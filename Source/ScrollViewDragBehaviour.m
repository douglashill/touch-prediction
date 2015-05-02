// Douglas Hill, April 2015

#import "ScrollViewDragBehaviour.h"

@interface ScrollViewDragBehaviour () <UIScrollViewDelegate>

@property (nonatomic, strong, readonly) UIScrollView *scrollView;

@end

@implementation ScrollViewDragBehaviour
{
	UIScrollView *_scrollView;
}

@synthesize view = _view;

- (NSString *)description
{
	return @"Scroll view behaviour";
}

- (void)updatePositionAndBounds
{
	CGSize const size = [[[self view] superview] bounds].size;
	[[self scrollView] setContentSize:size];
	
	CGPoint const position = [[self view] center];
	[[self scrollView] setContentOffset:(CGPoint){
		.x = size.width - position.x,
		.y = size.height - position.y,
	}];
}

- (void)setView:(UIView *)view
{
	_view = view;
	
	[view addSubview:[self scrollView]];
	[view addGestureRecognizer:[[self scrollView] panGestureRecognizer]];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGSize const size = [scrollView contentSize];
	CGPoint const offset = [scrollView contentOffset];
	
	[[self view] setCenter:(CGPoint){
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
	[_scrollView setScrollsToTop:NO];
	
	return _scrollView;
}

@end
