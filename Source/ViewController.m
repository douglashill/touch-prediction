// Douglas Hill, April 2015

#import "ViewController.h"

#import "QuadraticMotionPredictionDragBehaviour.h"
#import "ScrollViewDragBehaviour.h"
#import "SimpleDragBehaviour.h"

@interface ViewController () <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) ScrollViewDragBehaviour *scrollViewBehaviour;
@property (nonatomic, strong, readonly) UIView *square;

@property (nonatomic, strong, readonly) SimpleDragBehaviour *simpleBehaviour;
@property (nonatomic, strong, readonly) UIView *simpleSquare;

@property (nonatomic, strong, readonly) QuadraticMotionPredictionDragBehaviour *quadBehaviour;
@property (nonatomic, strong, readonly) UIView *quadSquare;

@end

@implementation ViewController
{
	ScrollViewDragBehaviour *_scrollViewBehaviour;
	UIView *_square;
	
	SimpleDragBehaviour *_simpleBehaviour;
	UIView *_simpleSquare;
	
	QuadraticMotionPredictionDragBehaviour *_quadBehaviour;
	UIView *_quadSquare;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSLog(@"Incorrect initialiser “%s” sent to %@", __PRETTY_FUNCTION__, [self class]);
	return [self init];
}

- (instancetype)init
{
	self = [super initWithNibName:nil bundle:nil];
	return self;
}

- (void)loadView
{
	UIView *const view = [[UIView alloc] init];
	[view setBackgroundColor:[UIColor lightGrayColor]];
	[self setView:view];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[[self view] addSubview:[self square]];
	[[self view] addSubview:[self simpleSquare]];
	[[self view] addSubview:[self quadSquare]];
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[[self square] setCenter:CGPointMake(100, 100)];
	[[self scrollViewBehaviour] updatePositionAndBounds];
	
	[[self simpleSquare] setCenter:CGPointMake(100, 200)];
	
	[[self quadSquare] setCenter:CGPointMake(100, 300)];
}

#pragma mark -

- (ScrollViewDragBehaviour *)scrollViewBehaviour
{
	if (_scrollViewBehaviour) return _scrollViewBehaviour;
	
	_scrollViewBehaviour = [[ScrollViewDragBehaviour alloc] init];
	
	return _scrollViewBehaviour;
}

- (UIView *)square
{
	if (_square) return _square;
	
	_square = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 84, 84)];
	[_square setBackgroundColor:[UIColor orangeColor]];
	
	[[self scrollViewBehaviour] setView:_square];
	
	UILabel *const label = [[UILabel alloc] init];
	[label setText:@"Scroll view"];
	[_square addSubview:label];
	[label sizeToFit];
	
	return _square;
}

- (SimpleDragBehaviour *)simpleBehaviour
{
	if (_simpleBehaviour) return _simpleBehaviour;
	
	_simpleBehaviour = [[SimpleDragBehaviour alloc] init];
	
	return _simpleBehaviour;
}

- (UIView *)simpleSquare
{
	if (_simpleSquare) return _simpleSquare;
	
	_simpleSquare = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 84, 84)];
	[_simpleSquare setBackgroundColor:[UIColor cyanColor]];
	
	[[self simpleBehaviour] setView:_simpleSquare];
	
	UILabel *const label = [[UILabel alloc] init];
	[label setText:@"Simple"];
	[_simpleSquare addSubview:label];
	[label sizeToFit];
	
	return _simpleSquare;
}

- (QuadraticMotionPredictionDragBehaviour *)quadBehaviour
{
	if (_quadBehaviour) return _quadBehaviour;
	
	_quadBehaviour = [[QuadraticMotionPredictionDragBehaviour alloc] init];
	
	return _quadBehaviour;
}

- (UIView *)quadSquare
{
	if (_quadSquare) return _quadSquare;
	
	_quadSquare = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 84, 84)];
	[_quadSquare setBackgroundColor:[UIColor magentaColor]];
	
	[[self quadBehaviour] setView:_quadSquare];
	
	UILabel *const label = [[UILabel alloc] init];
	[label setNumberOfLines:0];
	[label setText:@"Quadratic\nprediction"];
	[_quadSquare addSubview:label];
	[label sizeToFit];
	
	return _quadSquare;
}

@end
