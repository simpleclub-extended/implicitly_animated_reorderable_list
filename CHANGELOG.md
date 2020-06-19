# Changelog

## 0.2.2 - 0.2.3
- Bug fixes
- Fix #14

## 0.2.1
- `ImplicitlyAnimatedList` now always uses the latest items, even if `listEquals()` is `true`.

# 0.2.0
- Added support for headers and footers on the `ImplicitlyAnimatedReorderableList`.
- Added `child` property on `Reorderable` that can be used instead off the `builder` that will use a default elevation animation instead of being forced to specify your own custom animation.

## 0.1.5 to 0.1.10
- Bug fixes and performance improvements.

## 0.1.4
- Made `Handle` scroll aware to only initiate a drag when the scroll position didn't change.
- Added horizontal scrollDirection support for `ImplicitlyAnimatedReorderableList`

## 0.1.0
- Initial release