// Douglas Hill, April 2015

#import "ViewController.h"

@interface ViewController () <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong, readonly) UIView *square;

@end

@implementation ViewController
{
	UIScrollView *_scrollView;
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
	
	CGRect bounds = [[self view] bounds];
	
	[[self scrollView] setContentSize:bounds.size];
	[[self scrollView] setContentOffset:CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGSize const size = [scrollView contentSize];
	CGPoint const offset = [scrollView contentOffset];
	
	[[self square] setCenter:(CGPoint){
		.x = size.width - offset.x,
		.y = size.height - offset.y,
	}];
}

#pragma mark -

- (UIScrollView *)scrollView
{
	if (_scrollView) return _scrollView;
	
	_scrollView = [[UIScrollView alloc] init];
	[_scrollView setDelegate:self];
	[_scrollView setHidden:YES];
	
	return _scrollView;
}

- (UIView *)square
{
	if (_square) return _square;
	
	_square = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
	[_square setBackgroundColor:[UIColor redColor]];
	
	[_square addSubview:[self scrollView]];
	[_square addGestureRecognizer:[[self scrollView] panGestureRecognizer]];
	
	return _square;
}

@end
