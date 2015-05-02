// Douglas Hill, April 2015

@import UIKit;

#import "ViewBehaviour.h"

@interface MotionPredictingDragBehaviour : NSObject <ViewBehaviour>

/// Designated initialiser
- (instancetype)initWithFramesToPredict:(NSUInteger)framesToPredict polynomialDegree:(NSUInteger)polynomialDegree maxObservations:(NSUInteger)maxObservations __attribute((objc_designated_initializer));

/// The number of frames into the future for positions to be predicted, where a frame is one sixtieth of a second. 2 or 3 is recommended. Higher values increase noise and overshoot.
@property (nonatomic) NSUInteger framesToPredict;

/// The degree of the polynomial model used for prediction positions. Use 1 for linear or 2 for quadratic. Higher order polynomials tend to result in overfitting and noisy results, so are not recommended.
@property (nonatomic) NSUInteger polynomialDegree;

/// The number of previous positions to use when predicting future positions. Higher values results in smoother output (less noise), but increase overshoot and lag. Higher order polynomial models require more observations to avoid noisy output.
@property (nonatomic, readonly) NSUInteger maxObservations;

@end
