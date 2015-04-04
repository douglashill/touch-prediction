// Douglas Hill, April 2015

@import UIKit;

@interface ScrollViewDragBehaviour : NSObject

@property (nonatomic, strong) UIView *view;

- (void)updatePositionAndBounds;

@end
