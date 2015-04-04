// Douglas Hill, April 2015

#import "SimpleDragBehaviour.h"

@implementation SimpleDragBehaviour

- (void)setView:(UIView *)view
{
	_view = view;
	
	UIPanGestureRecognizer *const recogniser = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	[view addGestureRecognizer:recogniser];
}

- (void)handlePan:(UIPanGestureRecognizer *)recogniser
{
	UIView *const view = [recogniser view];
	
	CGPoint const translation = [recogniser translationInView:view];
	
	CGPoint position = [view center];
	position.x += translation.x;
	position.y += translation.y;
	[view setCenter:position];
	
	[recogniser setTranslation:CGPointZero inView:view];
}

@end
