// Douglas Hill, April 2015

#import "ViewController.h"

#import "MotionPredictingDragBehaviour.h"
#import "ScrollViewDragBehaviour.h"
#import "SimpleDragBehaviour.h"

static NSString *const behaviourKey = @"behaviour";
static NSString *const viewKey = @"view";

@interface ViewController () <UIScrollViewDelegate>

/// An array of dictionaries, which each contain a view and its attached behaviour.
@property (nonatomic, strong, readonly) NSArray *dragViewDictionaries;

@property (nonatomic, strong, readonly) ScrollViewDragBehaviour *scrollViewBehaviour;

@end

@implementation ViewController
{
	NSArray *_dragViewDictionaries;
	ScrollViewDragBehaviour *_scrollViewBehaviour;
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
	
	for (NSDictionary *dictionary in [self dragViewDictionaries]) {
		[[self view] addSubview:dictionary[viewKey]];
	}
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	CGFloat y = 100;
	for (NSDictionary *dictionary in [self dragViewDictionaries]) {
		[dictionary[viewKey] setCenter:CGPointMake(100, y)];
		y += 100;
	}
	
	[[self scrollViewBehaviour] updatePositionAndBounds];
}

#pragma mark -

NSDictionary *dragViewDictionary(id <ViewBehaviour> behaviour, UIColor *colour)
{
	UIView *const view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 84, 84)];
	[view setBackgroundColor:colour];
	
	[behaviour setView:view];
	
	UILabel *const label = [[UILabel alloc] init];
	[label setFrame:[view bounds]];
	[label setNumberOfLines:0];
	[label setText:[behaviour description]];
	[label setTextAlignment:NSTextAlignmentCenter];
	[view addSubview:label];
	
	return @{behaviourKey : behaviour, viewKey : view};
}

- (NSArray *)dragViewDictionaries
{
	if (_dragViewDictionaries) return _dragViewDictionaries;
	
	NSMutableArray *dragViewDictionaries = [NSMutableArray array];
	
	[dragViewDictionaries addObject:dragViewDictionary([self scrollViewBehaviour], [UIColor orangeColor])];
	[dragViewDictionaries addObject:dragViewDictionary([[SimpleDragBehaviour alloc] init], [UIColor cyanColor])];
	[dragViewDictionaries addObject:dragViewDictionary([[MotionPredictingDragBehaviour alloc] init], [UIColor magentaColor])];
	
	_dragViewDictionaries = dragViewDictionaries;
	
	return _dragViewDictionaries;
}

- (ScrollViewDragBehaviour *)scrollViewBehaviour
{
	if (_scrollViewBehaviour) return _scrollViewBehaviour;
	
	_scrollViewBehaviour = [[ScrollViewDragBehaviour alloc] init];
	
	return _scrollViewBehaviour;
}

@end
