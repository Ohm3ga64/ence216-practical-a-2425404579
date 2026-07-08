# Answers

## Checkpoint 1
Only `build()` prints again after a hot reload. `initState()` runs exactly
once, when the State object is first created, whereas hot reload keeps that
same State object alive and just re-invokes `build()` to redraw the UI with
the updated code.

## Section 4 - Why you need setState()
Mutating `_qty` outside of `setState()` still changes the underlying data
(a debugPrint confirms this), but Flutter has no way of knowing the widget's
state changed, so it never reschedules a `build()` call and the screen stays
visually out of sync until `setState()` -- even an empty one -- tells the
framework to rebuild.
