// Douglas Hill, April 2015

#import "ViewController.h"

#import "ScrollViewDragBehaviour.h"

@interface ViewController () <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) ScrollViewDragBehaviour *scrollViewBehaviour;
@property (nonatomic, strong, readonly) UIView *square;

@end

@implementation ViewController
{
	ScrollViewDragBehaviour *_scrollViewBehaviour;
	UIView *_square;
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
}

- (void)viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	
	[[self square] setCenter:CGPointMake(100, 100)];
	[[self scrollViewBehaviour] updatePositionAndBounds];
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

@end
