# Touch prediction #

This project is an investigation into using motion prediction to compensate for touch screen lag, which could be used to create more responsive dragging and drawing interactions.

## Status ##

An iOS app shows colours squares that may be dragged with different behaviours attached. Basic motion prediction is working, although not production-ready; it is noisy and overshoots.

Last tested with Xcode 6.3 and the iOS 8.3 SDK.

## Future work ##

The next approach to try is an adaptive filter, which compares previous predictions to actual observations and changes the filter parameters to minimise the prediction error.

## Licence ##

MIT license — see License.txt
