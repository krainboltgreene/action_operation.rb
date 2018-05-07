# Changelog

## 2.0.0

  - [breaking] We now use methods instead of passing around procs defined with `step()`, we now use methods
  - [breaking] Since we don't use procs, we can't use receiver or as, now it's just up to the step to do delegation
  - [breaking] renamed the `state()` function to be called `schema()`
  - [breaking] `error` listings are now defined with `catch`
  - [breaking] `error`'s no longer have a receiver or an as property
  - [breaking] `error`'s had a `catch` property, that is now named `exception`
  - [breaking] Failure steps received a list of arguments (`exception`, `state.to_h`, and `step.name`), now it returns a kwarg: `exception:, state: state, step: step` where `state` is the schema wrapped state and `step` is the actual step struct
  - [breaking] `fresh()` now requires a `state:` kwarg

## 1.0.0

  - Initial release
