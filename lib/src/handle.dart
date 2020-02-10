import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src.dart';

class Handle extends StatefulWidget {
  final Widget child;
  final Duration delay;
  Handle({
    Key key,
    @required this.child,
    this.delay = const Duration(milliseconds: 0),
  })  : assert(delay != null && delay >= Duration.zero),
        assert(child != null),
        super(key: key);

  @override
  _HandleState createState() => _HandleState();
}

class _HandleState extends State<Handle> {
  bool _inDrag = false;
  bool get _isVertical => _list?.isVertical ?? true;

  double _dragStart;
  double _dragEnd;
  Offset _pointer;
  Handler _handler;

  ImplicitlyAnimatedReorderableListState _list;
  ReorderableState _item;

  double get delta => (_dragEnd ?? 0) - (_dragStart ?? 0);

  void _onDragStarted() {
    if (_inDrag) return;

    _inDrag = true;
    _dragStart = _isVertical ? _pointer.dy : _pointer.dx;

    HapticFeedback.mediumImpact();

    _list?.onDragStarted(_item?.key);
    _item?.setState(() {});
  }

  void _onDragUpdated(bool upward) {
    _dragEnd = _isVertical ? _pointer.dy : _pointer.dx;
    _list?.onDragUpdated(delta, isUpward: upward);
  }

  void _onDragEnded() {
    _inDrag = false;

    _handler?.cancel();
    _list?.onDragEnded();

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    _list = ImplicitlyAnimatedReorderableList.of(context);
    assert(_list != null, 'No ImplicitlyAnimatedListView was found in the hirachy!');
    _item = Reorderable.of(context);
    assert(_item != null, 'No ReorderableItem was found in the hirachy!');

    return Listener(
      onPointerDown: (event) {
        _pointer = event.localPosition;

        if (!_inDrag) {
          _handler?.cancel();
          _handler = postDuration(
            widget.delay,
            _onDragStarted,
          );
        }
      },
      onPointerMove: (event) {
        _pointer = event.localPosition;
        final delta = _isVertical ? event.delta.dy : event.delta.dx;

        if (_inDrag) _onDragUpdated(delta.isNegative);
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