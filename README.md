# Touch prediction #

This project is an investigation into using motion prediction to compensate for touch screen latency, which could be used to create more responsive dragging and drawing interactions.

The project builds an iOS app demonstrating a few different dragging behaviours, using Objective-C and frameworks in the iOS SDK.

## Status ##

Basic motion prediction is working, although not production-ready due to noise (shaking) and overshooting (spring-like behaviour).

Last tested with Xcode 6.3 and the iOS 8.3 SDK.

## Inventory #

 - The `ViewController` class sets up views with attached [behaviours][OB].
 - The `MotionPredictingDragBehaviour` class implements dragging with motion prediction.
 - The `SimpleDragBehaviour` class implements dragging without motion prediction, and is included as a baseline. 
 - The `ScrollViewDragBehaviour` class is not related to motion prediction. It is an experiment implementing dragging using a `UIScrollView` rather than directly using a `UIPanGestureRecognizer`. This provides interruptible deceleration ‘for free’.

## Getting started ##

Clone this repository and open *Dragging.xcodeproj*. The prediction parameters can be adjusted in the method `dragViewDictionaries` in *Source/ViewController.m*. The project builds an app that ought to be run on a device (not the simulator), on as large a screen as possible so that latency can be more easily observed. A full-size iPad is preferred.

## Background ##

When movement of a finger on a touch screen is used to move an object rendered on the screen (dragging), there is a time delay between when the touch moves and when the object is rendered in the matching location. This is the touch screen’s *panning latency*, and is most noticeable when moving fast on a large touch screen. This can be seen by dragging the view with the `SimpleDragBehaviour` in the demo app: drag quickly and it can not keep up with the input touch.

This project aims to compensate for this delay by rendering the object at a predicted future position. This is done by modelling the touch’s position as a function of time and parameters estimated from the stream of previous touch positions (the observations), then extrapolating to predict a future position.

The `MotionPredictingDragBehaviour` class implements motion prediction using a polynomial model. For example, for a quadratic model ([a polynomial of degree 2][WDP]), the position, p, is modelled as:

> p = p<sub>0</sub> + v<sub>0</sub>t + a<sub>0</sub>t<sup>2</sup>

Where t is time, and p<sub>0</sub>, v<sub>0</sub> and a<sub>0</sub> are the estimated parameters.

These parameters are estimated using [ordinary least squares linear regression][WOLS], which finds the parameters that best fit the previously observed touch positions.

`MotionPredictingDragBehaviour` has three configurable properties:

 - The class supports predicting a configurable time into the future. When predicting further into the future there is more chance for reality to diverge from the prediction, so there is more noise and overshoot in the output. The touch screen latency seems to be about three frames on an iPad Air, where a frame is one sixtieth of a second, so ideally prediction would be ahead by the same time.
 - It uses a polynomial model of configurable degree. Higher degree models tend to result in overfitting and more noisy results.
 - The number of previous position observations to use is configurable. Higher values results in smoother output (less noise), but increase overshoot and lag. Higher order polynomial models require more observations to avoid noisy output.

## Results ##

The best setup will depend on the goals of the application, but subjectively `MotionPredictingDragBehaviour` calculates the most pleasing positions by predicting two frames ahead, using a linear model, with up to three observations.

	[[MotionPredictingDragBehaviour alloc] initWithFramesToPredict:2 polynomialDegree:1 maxObservations:3]

## Future work ##

Instead of a polynomial model, try predicting circular motion. Fingers will naturally follow arcs due to the mechanics of wrists and elbows. This is expected to be a marginal improvement at most — except in the case of tight circular motion, which polynomial models handle poorly.

Try using an adaptive filter, which compares previous predictions to actual observations and changes the filter parameters to minimise the prediction error.

## Licence ##

MIT license — see License.txt

[OB]: http://www.objc.io/issue-13/behaviors.html
[WDP]: https://en.wikipedia.org/wiki/Degree_of_a_polynomial
[WOLS]: http://en.wikipedia.org/wiki/Linear_regression#Least-squares_estimation_and_related_techniques
