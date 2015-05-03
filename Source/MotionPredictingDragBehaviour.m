// Douglas Hill, April 2015

#import "MotionPredictingDragBehaviour.h"

#import "LinearAlgebraAdditions.h"
@import Accelerate;

static CGFloat predictPosition(CFTimeInterval time, double *constants, la_count_t countOfConstants)
{
	CGFloat position = 0;
	for (la_count_t idx = 0; idx < countOfConstants; ++idx) {
		position += constants[idx] * pow(time, idx);
	}
	
	return position;
}

@interface MotionPredictingDragBehaviour ()

@property (nonatomic, strong, readonly) CADisplayLink *displayLink;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *recogniser;

@end

@implementation MotionPredictingDragBehaviour
{
	CADisplayLink *_displayLink;
	UIPanGestureRecognizer *_recogniser;
	
	double *_previousXPositions;
	double *_previousYPositions;
	double *_observationTimes;
	la_count_t _countOfPreviousPositions;
}

@synthesize view = _view;

- (void)dealloc
{
	free(_previousXPositions);
	free(_previousYPositions);
	free(_observationTimes);
}

- (instancetype)init
{
	return [self initWithFramesToPredict:0 polynomialDegree:0 maxObservations:0];
}

- (instancetype)initWithFramesToPredict:(NSUInteger)framesToPredict polynomialDegree:(NSUInteger)polynomialDegree maxObservations:(NSUInteger)maxObservations
{
	self = [super init];
	if (self == nil) return nil;
	
	_framesToPredict = framesToPredict;
	_polynomialDegree = polynomialDegree;
	_maxObservations = maxObservations;
	
	_previousXPositions = malloc(maxObservations * sizeof *_previousXPositions);
	_previousYPositions = malloc(maxObservations * sizeof *_previousYPositions);
	_observationTimes = malloc(maxObservations * sizeof *_observationTimes);
	
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%lu %@\ndegree %lu\n%lu obs", (unsigned long)[self framesToPredict], [self framesToPredict] == 1 ? @"frame" : @"frames", (unsigned long)[self polynomialDegree], (unsigned long)[self maxObservations]];
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
	
	la_count_t const countOfColumns = [self polynomialDegree] + 1;
	
	if (_countOfPreviousPositions < countOfColumns) {
		return;
	}
	
	CFTimeInterval const now = CACurrentMediaTime();
	
	double *timeMatrixBuffer = malloc(countOfColumns * _countOfPreviousPositions * sizeof(double));
	for (la_count_t rowIndex = 0; rowIndex < _countOfPreviousPositions; ++rowIndex) {
		
		double const relativeTime = _observationTimes[rowIndex] - now;
		
		for (la_count_t colIndex = 0; colIndex < countOfColumns; ++colIndex) {
			timeMatrixBuffer[countOfColumns * rowIndex + colIndex] = pow(relativeTime, colIndex);
		}
	}
	la_object_t const timeMatrix = la_matrix_from_double_buffer(timeMatrixBuffer, _countOfPreviousPositions, countOfColumns, countOfColumns, LA_NO_HINT, LA_ATTRIBUTE_ENABLE_LOGGING);
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
	
	double xSolValues[countOfColumns];
	la_status_t const xStatus = la_vector_to_double_buffer(xSolValues, 1, xSolution);
	if (xStatus != LA_SUCCESS) {
		NSLog(@"Could not read x values: %@", @(xStatus));
		return;
	}
	
	double ySolValues[countOfColumns];
	la_status_t const yStatus = la_vector_to_double_buffer(ySolValues, 1, ySolution);
	if (yStatus != LA_SUCCESS) {
		NSLog(@"Could not read y values: %@", @(yStatus));
		return;
	}
	
//	NSLog(@"SUCCESS");
	
	CFTimeInterval const future = [self framesToPredict] / 60.0;
	CGPoint const futurePosition = CGPointMake(predictPosition(future, xSolValues, countOfColumns), predictPosition(future, ySolValues, countOfColumns));
	
	[view setCenter:futurePosition];
}

- (void)savePositionObservation:(CGPoint)position
{
	if ([self maxObservations] == 0) {
		return;
	}
	
	if (_countOfPreviousPositions == [self maxObservations]) {
		// Remove top entries by shifting everything else up.
		memmove(_previousXPositions, _previousXPositions + 1, ([self maxObservations] - 1) * sizeof _previousXPositions[0]);
		memmove(_previousYPositions, _previousYPositions + 1, ([self maxObservations] - 1) * sizeof _previousYPositions[0]);
		memmove(_observationTimes,   _observationTimes + 1,   ([self maxObservations] - 1) * sizeof _observationTimes[0]);
		
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
