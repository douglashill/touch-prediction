// Douglas Hill, April 2015

#import "QuadraticMotionPredictionDragBehaviour.h"

@import Accelerate;

static CFTimeInterval const future = 3.0 / 60.0;
static la_count_t const maxObservations = 8;

static NSString *LAObjectDescription(la_object_t object)
{
	la_count_t const cols = la_matrix_cols(object);
	la_count_t const rows = la_matrix_rows(object);
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@; Cols: %ld; Rows: %ld; Status: %ld", [object class], cols, rows, la_status(object)];
	
	double buffer[cols * rows];
	la_status_t const status = la_matrix_to_double_buffer(buffer, cols, object);
	
	if (status != LA_SUCCESS) {
		[description appendFormat:@"\nCould not read values: %ld", status];
		return description;
	}
	
	[description appendString:@"\n"];
	
	for (la_count_t rowIndex = 0; rowIndex < rows; ++rowIndex) {
		for (la_count_t colIndex = 0; colIndex < cols; ++colIndex) {
			[description appendFormat:@"%g ", buffer[rowIndex * cols + colIndex]];
		}
		[description appendString:@"\n"];
	}
	
	[description appendString:@"\n"];
	
	return description;
}

LA_FUNCTION LA_NONNULL LA_AVAILABILITY LA_RETURNS_RETAINED
la_object_t dh_la_solve(la_object_t matrix_system, la_object_t obj_rhs)
{
	NSCAssert(la_matrix_rows(matrix_system) == la_matrix_rows(obj_rhs), @"Dimension mismatch");
	NSCAssert(la_matrix_rows(matrix_system) >= la_matrix_cols(matrix_system), @"Dimension mismatch: not enough observations");
	
	__CLPK_integer m = la_matrix_rows(matrix_system); // Height of A and b, number of observations
	__CLPK_integer n = la_matrix_cols(matrix_system); // Width of A and height of x, number of coefficients
	__CLPK_integer nrhs = la_matrix_cols(obj_rhs);    // Width of b and x
	
	double *Adata = malloc(m * n * sizeof(double));
	la_status_t aReadingStatus = la_matrix_to_double_buffer(Adata, m, la_transpose(matrix_system));
	
	double *bdata = malloc(m * nrhs * sizeof(double));
	la_status_t bReadingStatus = la_matrix_to_double_buffer(bdata, m, la_transpose(obj_rhs));
	
	// Find the least squares solution to the overdetermined linear system Ax = b
	// http://www.netlib.org/lapack/lug/node27.html
	
	char trans = 'n';
//	__CLPK_integer optimumWorkSize;
	__CLPK_doublereal optimumWorkSizeFloat;
	__CLPK_integer getOptimumWorkSize = -1;
	__CLPK_integer status;
	dgels_(&trans, &m, &n, &nrhs, Adata, &m, bdata, &m, &optimumWorkSizeFloat, &getOptimumWorkSize, &status);
	
	if (status < 0) {
		printf("Could not find optimum workspace size. Status is: %ld\n\n", (long)status);
		return nil;
	}
	
	__CLPK_integer optimumWorkSize = optimumWorkSizeFloat; // This really looks like what you’re supposed to do.
	__CLPK_doublereal *workspace = malloc(optimumWorkSize * sizeof(__CLPK_doublereal));
	dgels_(&trans, &m, &n, &nrhs, Adata, &m, bdata, &m, workspace, &optimumWorkSize, &status);
	free(workspace);
	workspace = NULL;
	
	free(Adata);
	Adata = NULL;
	
	if (status < 0) {
		printf("Could not solve for x. Status is: %ld\n\n", (long)status);
		return nil;
	}
	
	la_object_t X = la_transpose(la_matrix_from_double_buffer(bdata, nrhs, n, m, LA_NO_HINT, LA_ATTRIBUTE_ENABLE_LOGGING));
	
	free(bdata);
	bdata = NULL;
	
	return X;
	
	// TODO: Fix returning early leaking memory
}

static CGFloat predictPosition(CFTimeInterval time, double *constants)
{
	return constants[0] * time * time + constants[1] * time + constants[2];
}

@interface QuadraticMotionPredictionDragBehaviour ()

@property (nonatomic, strong, readonly) CADisplayLink *displayLink;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *recogniser;

@end

@implementation QuadraticMotionPredictionDragBehaviour
{
	CADisplayLink *_displayLink;
	UIPanGestureRecognizer *_recogniser;
	
	double _previousXPositions[maxObservations];
	double _previousYPositions[maxObservations];
	double _observationTimes[maxObservations];
	la_count_t _countOfPreviousPositions;
}

- (void)setView:(UIView *)view
{
	_view = view;
	
	[view addGestureRecognizer:[self recogniser]];
}

- (void)handlePan:(UIPanGestureRecognizer *)recogniser
{
	switch ([recogniser state]) {
		case UIGestureRecognizerStatePossible:
			break;
			
		case UIGestureRecognizerStateBegan:
			_countOfPreviousPositions = 0;
			[[self displayLink] setPaused:NO];
			break;
			
		case UIGestureRecognizerStateChanged:
			break;
			
		case UIGestureRecognizerStateEnded: case UIGestureRecognizerStateCancelled: case UIGestureRecognizerStateFailed:
			[[self displayLink] setPaused:YES];
			break;
	}
}

- (void)update:(CADisplayLink *)sender
{
	UIPanGestureRecognizer *recogniser = [self recogniser];
	UIView *const view = [recogniser view];
	
	CGPoint const currentPosition = [recogniser locationInView:[view superview]];
	[self savePositionObservation:currentPosition];
	
	// Fallback
	[view setCenter:currentPosition];
	
	if (_countOfPreviousPositions < 3) {
		return;
	}
	
	CFTimeInterval const now = CACurrentMediaTime();
	
	static la_count_t const cols = 3;
	double *timeMatrixBuffer = malloc(cols * _countOfPreviousPositions * sizeof(double));
	for (la_count_t idx = 0; idx < _countOfPreviousPositions; ++idx) {
		
		double const relativeTime = _observationTimes[idx] - now;
		
		timeMatrixBuffer[cols * idx] = relativeTime * relativeTime;
		timeMatrixBuffer[cols * idx + 1] = relativeTime;
		timeMatrixBuffer[cols * idx + 2] = 1;
	}
	la_object_t const timeMatrix = la_matrix_from_double_buffer(timeMatrixBuffer, _countOfPreviousPositions, cols, cols, LA_NO_HINT, LA_ATTRIBUTE_ENABLE_LOGGING);
	if (la_status(timeMatrix) != LA_SUCCESS) {
		NSLog(@"Could not create time matrix: %@", @(la_status(timeMatrix)));
	}
	free(timeMatrixBuffer);
	timeMatrixBuffer = NULL;
	
//	NSLog(@"timeMatrix: %@", LAObjectDescription(timeMatrix));
	
	la_object_t const xPositionsVector = la_vector_from_double_buffer(_previousXPositions, _countOfPreviousPositions, 1, LA_ATTRIBUTE_ENABLE_LOGGING);
	if (la_status(xPositionsVector) != LA_SUCCESS) {
		NSLog(@"Could not create x positions vector: %@", @(la_status(xPositionsVector)));
	}
	
//	NSLog(@"xPositionsVector: %@", LAObjectDescription(xPositionsVector));
	
	la_object_t const yPositionsVector = la_vector_from_double_buffer(_previousYPositions, _countOfPreviousPositions, 1, LA_ATTRIBUTE_ENABLE_LOGGING);
	if (la_status(yPositionsVector) != LA_SUCCESS) {
		NSLog(@"Could not create y positions vector: %@", @(la_status(yPositionsVector)));
	}
	
//	NSLog(@"yPositionsVector: %@", LAObjectDescription(yPositionsVector));
	
	la_object_t const xSolution = dh_la_solve(timeMatrix, xPositionsVector);
	if (xSolution == nil || la_status(xSolution) != LA_SUCCESS) {
		NSLog(@"Could not solve x equation: %@", @(la_status(xSolution)));
		return;
	}
	
	la_object_t const ySolution = dh_la_solve(timeMatrix, yPositionsVector);
	if (ySolution == nil || la_status(ySolution) != LA_SUCCESS) {
		NSLog(@"Could not solve y equation: %@", @(la_status(ySolution)));
		return;
	}
	
	double xSolValues[cols];
	la_status_t const xStatus = la_vector_to_double_buffer(xSolValues, 1, xSolution);
	if (xStatus != LA_SUCCESS) {
		NSLog(@"Could not read x values: %@", @(xStatus));
		return;
	}
	
	double ySolValues[cols];
	la_status_t const yStatus = la_vector_to_double_buffer(ySolValues, 1, ySolution);
	if (yStatus != LA_SUCCESS) {
		NSLog(@"Could not read y values: %@", @(yStatus));
		return;
	}
	
//	NSLog(@"SUCCESS");
	
	CGPoint const futurePosition = CGPointMake(predictPosition(future, xSolValues), predictPosition(future, ySolValues));
	
	[view setCenter:CGPointMake(predictPosition(future, xSolValues), predictPosition(future, ySolValues))];
	[view setCenter:futurePosition];
}

- (void)savePositionObservation:(CGPoint)position
{
	if (_countOfPreviousPositions == maxObservations) {
		// Remove top entries by shifting everything else up.
		memmove(_previousXPositions, _previousXPositions + 1, (maxObservations - 1) * sizeof _previousXPositions[0]);
		memmove(_previousYPositions, _previousYPositions + 1, (maxObservations - 1) * sizeof _previousYPositions[0]);
		memmove(_observationTimes,   _observationTimes + 1,   (maxObservations - 1) * sizeof _observationTimes[0]);
		
		--_countOfPreviousPositions;
	}
	
	_previousXPositions[_countOfPreviousPositions] = (double)position.x;
	_previousYPositions[_countOfPreviousPositions] = (double)position.y;
	_observationTimes[_countOfPreviousPositions] = CACurrentMediaTime();
	
	++_countOfPreviousPositions;
}

#pragma mark -

- (CADisplayLink *)displayLink
{
	if (_displayLink) return _displayLink;
	
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update:)];
	[_displayLink setPaused:YES];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
	
	return _displayLink;
}

- (UIPanGestureRecognizer *)recogniser
{
	if (_recogniser) return _recogniser;
	
	_recogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	
	return _recogniser;
}

@end
