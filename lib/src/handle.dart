import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src.dart';

/// A Handle is used to initiate a drag/reorder of an item inside an
/// [ImplicitlyAnimatedReorderableList].
///
/// A Handle must have a [Reorderable] and an [ImplicitlyAnimatedReorderableList]
/// as its ancestor.
class Handle extends StatefulWidget {
  /// The child of this Handle that can initiate a reorder.
  ///
  /// This might for instance be an [Icon] or a [ListTile].
  final Widget child;

  /// The delay between when a pointer touched the [child] and
  /// when the drag is initiated.
  ///
  /// If the Handle wraps the whole item, the delay should be greater
  /// than `Duration.zero` as otherwise the list might become unscrollable.
  final Duration delay;

  /// Whether to vibrate when a drag has been initiated.
  final bool vibrate;
  const Handle({
    Key key,
    @required this.child,
    this.delay = Duration.zero,
    this.vibrate = true,
  })  : assert(delay != null),
        assert(child != null),
        assert(vibrate != null),
        super(key: key);

  @override
  _HandleState createState() => _HandleState();
}

class _HandleState extends State<Handle> {
  // The parent list.
  ImplicitlyAnimatedReorderableListState _list;
  // Whether the ImplicitlyAnimatedReorderableList has a
  // scrollDirection of Axis.vertical.
  bool get _isVertical => _list?.isVertical ?? true;

  // Only initiate a drag when the list didn't scroll so as
  // to avoid to initiate a drag when actually the user wants
  // to scroll the list.
  double _dragStartScrollOffset;
  static const double _maxScrollDelta = 5.0;

  // The parent Reorderable item.
  ReorderableState _reorderable;
  // A custom handler used to cancel the pending onDragStart callbacks.
  Handler _handler;

  bool _inDrag = false;

  double _initialOffset;
  double _currentOffset;
  double get _delta => (_currentOffset ?? 0) - (_initialOffset ?? 0);

  void _onDragStarted(Offset pointer) {
    final delta = (_list.scrollOffset - _dragStartScrollOffset).abs();
    if (_inDrag || delta > _maxScrollDelta) return;

    _inDrag = true;
    _initialOffset = _isVertical ? pointer.dy : pointer.dx;

    _list?.onDragStarted(_reorderable?.key);
    _reorderable.rebuild();

    _vibrate();
  }

  void _onDragUpdated(Offset pointer, bool upward) {
    _currentOffset = _isVertical ? pointer.dy : pointer.dx;
    _list?.onDragUpdated(_delta, isUpward: upward);
  }

  void _onDragEnded() {
    _inDrag = false;

    _handler?.cancel();
    _list?.onDragEnded();

    _vibrate();
  }

  void _vibrate() {
    if (widget.vibrate) HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    _list ??= ImplicitlyAnimatedReorderableList.of(context);
    assert(_list != null, 'No ancestor ImplicitlyAnimatedReorderableList was found in the hierarchy!');
    _reorderable ??= Reorderable.of(context);
    assert(_reorderable != null, 'No ancestor Reorderable was found in the hierarchy!');

    return Listener(
      onPointerDown: (event) {
        final pointer = event.localPosition;

        if (!_inDrag) {
          _dragStartScrollOffset = _list.scrollOffset;

          _handler?.cancel();
          _handler = postDuration(
            widget.delay,
            () => _onDragStarted(pointer),
          );
        }
      },
      onPointerMove: (event) {
        final pointer = event.localPosition;
        final delta = _isVertical ? event.delta.dy : event.delta.dx;

        if (_inDrag) _onDragUpdated(pointer, delta.isNegative);
      },
      onPointerUp: (event) {
        _handler?.cancel();

        if (_inDrag) _onDragEnded();
      },
      onPointerCancel: (event) {
        _handler?.cancel();

        if (_inDrag) _onDragEnded();
      },
      child: widget.child,
    );
  }
}
