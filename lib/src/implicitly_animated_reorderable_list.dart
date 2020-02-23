import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'src.dart';

typedef ReorderStartedCallback<E> = void Function(E item, int index);

typedef ReorderFinishedCallback<E> = void Function(E item, int from, int to, List<E> newItems);

class ImplicitlyAnimatedReorderableList<E> extends ImplicitlyAnimatedListBase<Reorderable, E> {
  /// Whether the scroll view scrolls in the reading direction.
  ///
  /// Defaults to false.
  final bool reverse;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// An object that can be used to control the position to which this scroll
  /// view is scrolled.
  ///
  /// Must be null if [primary] is true.
  ///
  /// A [ScrollController] serves several purposes. It can be used to control
  /// the initial scroll position (see [ScrollController.initialScrollOffset]).
  /// It can be used to control whether the scroll view should automatically
  /// save and restore its scroll position in the [PageStorage] (see
  /// [ScrollController.keepScrollOffset]). It can be used to read the current
  /// scroll position (see [ScrollController.offset]), or change it (see
  /// [ScrollController.animateTo]).
  final ScrollController controller;

  /// Whether this is the primary scroll view associated with the parent
  /// [PrimaryScrollController].
  ///
  /// On iOS, this identifies the scroll view that will scroll to top in
  /// response to a tap in the status bar.
  ///
  /// Defaults to true when [scrollDirection] is [Axis.vertical] and
  /// [controller] is null.
  final bool primary;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// Defaults to matching platform conventions.
  final ScrollPhysics physics;

  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  /// If the scroll view does not shrink wrap, then the scroll view will expand
  /// to the maximum allowed size in the [scrollDirection]. If the scroll view
  /// has unbounded constraints in the [scrollDirection], then [shrinkWrap] must
  /// be true.
  ///
  /// Shrink wrapping the content of the scroll view is significantly more
  /// expensive than expanding to the maximum allowed size because the content
  /// can expand and contract during scrolling, which means the size of the
  /// scroll view needs to be recomputed whenever the scroll position changes.
  ///
  /// Defaults to false.
  final bool shrinkWrap;

  /// The amount of space by which to inset the children.
  final EdgeInsetsGeometry padding;

  /// The duration of the animation of the [Reorderable] between dragged
  /// and normal state.
  final Duration dragDuration;

  /// Called in response to when an item changed from normal to dragged
  /// state and may be reordered.
  final ReorderStartedCallback<E> onReorderStarted;

  /// Called in response to when the dragged item has been released
  /// and animated to its final destination. Here you should update
  /// the underlying data in your model/bloc/database etc.
  ///
  /// The `item` parameter of the callback is the item that has been reordered
  /// `from` index `to` index. The `data` parameter represents the new data with
  /// the item already being correctly reordered.
  ///
  /// This parameter should not be null.
  final ReorderFinishedCallback<E> onReorderFinished;

  const ImplicitlyAnimatedReorderableList({
    Key key,
    @required List<E> items,
    @required AnimatedItemBuilder<Reorderable, E> itemBuilder,
    @required ItemDiffUtil<E> areItemsTheSame,
    RemovedItemBuilder<Reorderable, E> removeItemBuilder,
    UpdatedItemBuilder<Reorderable, E> updateItemBuilder,
    Duration insertDuration = const Duration(milliseconds: 500),
    Duration removeDuration = const Duration(milliseconds: 500),
    Duration updateDuration = const Duration(milliseconds: 500),
    @required this.onReorderFinished,
    this.onReorderStarted,
    this.dragDuration = const Duration(milliseconds: 300),
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
  })  : assert(itemBuilder != null),
        assert(areItemsTheSame != null),
        assert(onReorderFinished != null),
        assert(items != null),
        assert(
          dragDuration <= const Duration(milliseconds: 1500),
          'The drag duration should not be longer than 1500 milliseconds.',
        ),
        super(
          key: key,
          items: items,
          itemBuilder: itemBuilder,
          areItemsTheSame: areItemsTheSame,
          removeItemBuilder: removeItemBuilder,
          updateItemBuilder: updateItemBuilder,
          insertDuration: insertDuration,
          removeDuration: removeDuration,
          updateDuration: updateDuration,
        );

  @override
  ImplicitlyAnimatedReorderableListState<E> createState() => ImplicitlyAnimatedReorderableListState<E>();

  static ImplicitlyAnimatedReorderableListState of(BuildContext context) {
    return context.findAncestorStateOfType<ImplicitlyAnimatedReorderableListState>();
  }
}

class ImplicitlyAnimatedReorderableListState<E>
    extends ImplicitlyAnimatedListBaseState<Reorderable, ImplicitlyAnimatedReorderableList<E>, E> {
  GlobalKey _dragKey;
  ScrollController _controller;
  Timer _scrollAdjuster;

  _Item dragItem;
  Reorderable _dragWidget;
  VoidCallback _onDragEnd;

  bool get isVertical => widget.scrollDirection != Axis.horizontal;

  double _listSize = 0;
  double get scrollOffset => _controller.offset;
  double get _maxScrollOffset => _controller.position.maxScrollExtent;
  double get _scrollDelta => scrollOffset - _dragStartScrollOffset;
  bool get _canScroll => _maxScrollOffset > 0;

  bool _motionUp = false;
  bool get _up => _dragDelta.isNegative;

  bool _inDrag = false;
  bool get inDrag => _inDrag;

  double _dragStartOffset;
  double _dragStartScrollOffset;
  Key get dragKey => dragItem?.key;
  int get dragIndex => dragItem?.index;
  double get dragStart => dragItem.start + _dragDelta;
  double get dragEnd => dragItem.end + _dragDelta;
  double get dragCenter => dragItem.middle + _dragDelta;
  double get dragSize => isVertical ? dragItem.height : dragItem.width;

  final ValueNotifier<double> _dragDeltaNotifier = ValueNotifier(0.0);
  double get _dragDelta => _dragDeltaNotifier.value;
  set _dragDelta(double value) => _dragDeltaNotifier.value = value;

  final ValueNotifier<double> _pointerDeltaNotifier = ValueNotifier(0.0);
  double get _pointerDelta => _pointerDeltaNotifier.value;
  set _pointerDelta(double value) => _pointerDeltaNotifier.value = value;

  final Map<Key, ReorderableState> _items = {};
  final Map<Key, AnimationController> _itemTranslations = {};
  final Map<Key, _Item> _itemBoxes = {};

  _Item get closest => _closestList.firstOrNull;
  final List<_Item> _closestList = [];

  @override
  void initState() {
    super.initState();
    _dragKey = GlobalKey();

    // The list must have a ScrollController in order to adjust the
    // scroll position when the user drags an item outside the
    // current viewport.
    _controller = widget.controller ?? ScrollController();

    _addReorderableUpdateAnimationSupport();
  }

  void onDragStarted(Key key) {
    _onDragEnd?.call();

    _measureChild(key);
    dragItem = _itemBoxes[key];

    if (dragIndex != null) {
      final offset = _itemOffset(key);
      _dragStartOffset = isVertical ? offset.dy : offset.dx;
      _dragStartScrollOffset = scrollOffset;
      _findClosestItem();

      setState(() => _inDrag = true);

      widget.onReorderStarted?.call(dataSet[dragIndex], dragIndex);

      _adjustScrollPositionWhenNecessary();
    }
  }

  void onDragUpdated(double delta, {bool isUpward}) {
    if (dragKey == null || dragItem == null) return;

    if (isUpward != null) {
      _motionUp = isUpward;
    }

    // Allow the dragged item to be overscrolled to allow for
    // continous scrolling while in drag.
    final overscrollBound = _canScroll ? dragSize : 0;
    // Constrain the dragged item to the bounds of the list.
    final currentDelta = (_up ? dragItem.start : dragItem.end) + delta;
    final minDelta = -(dragItem.start + overscrollBound);
    final maxDelta = (_maxScrollOffset + _listSize) + overscrollBound;
    if (currentDelta < minDelta || currentDelta > maxDelta) {
      return;
    }

    _pointerDelta = delta.clamp(minDelta, maxDelta);
    _dragDelta = _pointerDelta + _scrollDelta;

    _findClosestItem();

    if (closest == null || closest.key == dragKey) return;

    _translateNextItem();
    _adjustPreviousItemTranslations();
  }

  void _findClosestItem() {
    _closestList.clear();
    for (final item in _itemBoxes.values) {
      if (item == dragItem) {
        item.distance = _pointerDelta.abs();
        _closestList.add(item);
      } else {
        final position = isVertical ? item.center.dy : item.center.dx;
        if ((_motionUp && dragStart < position) || (!_motionUp && dragEnd > position)) {
          item.distance = ((_up ? dragStart : dragEnd) - position).abs();
          _closestList.add(item);
        }
      }
    }
    _closestList.sort();
  }

  void _translateNextItem() {
    final key = closest.key;
    final translation = getTranslation(key);
    final center = closest.middle;

    if (_up) {
      if (dragStart < center && translation == 0.0) {
        _dispatchMove(key, dragSize);
      } else if (dragStart > center && translation != 0.0) {
        _dispatchMove(key, 0);
      }
    } else {
      if (dragEnd > center && translation == 0.0) {
        if (closest.distance > dragItem.start && !_canScroll) {
          return;
        }
        _dispatchMove(key, -dragSize);
      } else if (dragEnd < center && translation != 0.0) {
        _dispatchMove(key, 0);
      }
    }
  }

  void _adjustPreviousItemTranslations() {
    for (final item in _itemBoxes.values) {
      if (item == dragItem || item == closest) continue;

      final key = item.key;
      if (_itemTranslations[key]?.isAnimating == true) continue;

      final translation = getTranslation(key);

      final index = item.index;
      final closestIndex = closest.index;

      if (index > dragIndex) {
        if (translation == 0.0 && index < closestIndex) {
          _dispatchMove(key, -dragSize);
        } else if (translation != 0.0 && index > closestIndex) {
          _dispatchMove(key, 0);
        }
      } else if (index < dragIndex) {
        if (translation == 0.0 && index > closestIndex) {
          _dispatchMove(key, dragSize);
        } else if (translation != 0.0 && index < closestIndex) {
          _dispatchMove(key, 0);
        }
      }
    }
  }

  void _dispatchMove(Key key, double delta, {VoidCallback onEnd}) {
    double value = 0.0;
    final oldController = _itemTranslations[key];
    if (oldController != null) {
      value = oldController.value;

      oldController
        ..stop()
        ..dispose();
    }

    final start = min(value, delta);
    final end = max(value, delta);

    final controller = AnimationController(
      vsync: this,
      value: value,
      lowerBound: start,
      upperBound: end,
      duration: widget.dragDuration,
    );

    if (controller.upperBound == controller.lowerBound) {
      onEnd?.call();
      return;
    }

    _items[key]?.setTranslation(controller);

    // ignore: avoid_single_cascade_in_expression_statements
    controller.animateTo(
      delta,
      curve: Curves.easeInOut,
    )..whenCompleteOrCancel(
        () => onEnd?.call(),
      );

    _itemTranslations[key] = controller;
  }

  void _adjustScrollPositionWhenNecessary() {
    _scrollAdjuster?.cancel();
    _scrollAdjuster = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if ((_up && scrollOffset <= 0) || (!_up && scrollOffset >= _maxScrollOffset)) return;

      final dragBox = _dragKey?.renderBox;
      if (dragBox == null) return;

      final dragOffset = dragBox.localToGlobal(Offset.zero, ancestor: context.renderBox);
      final dragItemStart = isVertical ? dragOffset.dy : dragOffset.dx;
      final dragItemEnd = dragItemStart + dragSize;

      double delta;
      if (dragItemStart <= 0) {
        delta = dragItemStart;
      } else if (dragItemEnd >= _listSize) {
        delta = dragItemEnd - _listSize;
      }

      if (delta != null) {
        final atLowerBound = dragItemStart <= 0;
        delta = (delta.abs() / dragSize).clamp(0.1, 1.0);

        const maxSpeed = 20;
        final max = atLowerBound ? -maxSpeed : maxSpeed;
        final scrollDelta = max * delta;

        _controller.jumpTo(scrollOffset + scrollDelta);
        onDragUpdated(_pointerDelta);
      }
    });
  }

  void onDragEnded() {
    if (dragKey == null || _closestList.isEmpty) return;

    if (getTranslation(closest.key) == 0.0) {
      _dispatchMove(closest.key, _up ? dragSize : -dragSize);
    }

    _onDragEnd = () {
      if (dragIndex != null) {
        final toIndex = _itemBoxes[closest.key].index;
        final item = dataSet.removeAt(dragIndex);
        dataSet.insert(toIndex, item);

        widget.onReorderFinished?.call(
          item,
          dragIndex,
          toIndex,
          List<E>.from(dataSet),
        );
      }

      _cancelDrag();
    };

    final delta = closest != dragItem ? closest.start - dragStart : -_pointerDelta;

    _dispatchMove(
      dragKey,
      // Make sure not to pass a zero delta (i.e. the item didn't move)
      // as this would lead to the same upper and lower bound on the animation
      // controller, which is not allowed.
      delta != 0.0 ? delta : 0.5,
      onEnd: _onDragEnd,
    );

    _scrollAdjuster?.cancel();

    // jumpTo() disposes of the current drag event which
    // Scrollable expects us to do.
    _controller.jumpTo(_controller.offset);

    setState(() => _inDrag = false);
  }

  void _cancelDrag() {
    setState(() {
      dragItem = null;
      _onDragEnd = null;
      _dragWidget = null;
      _dragDelta = 0.0;
      _pointerDelta = 0.0;
      _scrollAdjuster?.cancel();

      for (final key in _itemTranslations.keys) {
        _items[key]?.setTranslation(null);
      }

      _itemTranslations.clear();
    });
  }

  double getTranslation(Key key) => key == dragKey ? _dragDelta : _itemTranslations[key]?.value ?? 0.0;

  void registerItem(ReorderableState item) {
    _items[item.key] = item;
  }

  Offset _itemOffset(Key key) {
    return _items[key]?.context?.renderBox?.localToGlobal(
          Offset.zero,
          ancestor: context.renderBox,
        );
  }

  bool _prevInDrag = false;

  void _onRebuild() {
    _itemBoxes.clear();

    final needsRebuild = _listSize == 0 || inDrag != _prevInDrag;
    _prevInDrag = inDrag;

    postFrame(() {
      _listSize = isVertical ? listKey.height : listKey.width;

      if (needsRebuild) setState(() {});
    });
  }

  void _measureChild(Key key, [int index]) {
    final box = _items[key].context?.renderBox;
    final offset = _itemOffset(key)?.translate(
      isVertical ? 0 : scrollOffset,
      isVertical ? scrollOffset : 0,
    );

    if (box != null && offset != null) {
      final i = index ?? _itemBoxes[key]?.index;
      _itemBoxes[key] = _Item(key, box, i, offset, isVertical);
    }
  }

  @override
  Widget build(BuildContext context) {
    _onRebuild();

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        AnimatedList(
          key: listKey,
          itemBuilder: (context, index, animation) {
            final item = dataSet[index];

            final Reorderable child = buildItem(context, animation, item, index);
            postFrame(() => _measureChild(child.key, index));

            if (dragKey != null && index == dragIndex) {
              final size = dragItem?.size;
              // Determine if the dragged widget should be hidden
              // immidiately, or with on frame delay in order to
              // avoid item flash.
              final mustRebuild = _dragWidget == null;

              _dragWidget = child;
              if (mustRebuild) postFrame(() => setState(() {}));

              // The placeholder of the dragged item.
              //
              // Make sure not to use the actual widget but only its size
              // when they have been determined, as a widget is only allowed
              // to be laid out once.
              return Invisible(
                invisible: !mustRebuild,
                child: mustRebuild ? child : SizedBox.fromSize(size: size),
              );
            }

            return child;
          },
          controller: _controller,
          scrollDirection: widget.scrollDirection,
          initialItemCount: newData.length,
          physics: inDrag ? const NeverScrollableScrollPhysics() : widget.physics,
          padding: widget.padding,
          primary: widget.primary,
          reverse: widget.reverse,
          shrinkWrap: widget.shrinkWrap,
        ),
        if (_dragWidget != null) _buildDraggedItem()
      ],
    );
  }

  Widget _buildDraggedItem() {
    return ValueListenableBuilder<double>(
      child: _dragWidget,
      valueListenable: _pointerDeltaNotifier,
      builder: (context, pointer, dragWidget) {
        final delta = _dragStartOffset + pointer;

        return Transform.translate(
          offset: Offset(
            isVertical ? 0 : delta,
            isVertical ? delta : 0,
          ),
          child: Container(
            key: _dragKey,
            child: dragWidget,
          ),
        );
      },
    );
  }

  @override
  Widget buildUpdatedItemWidget(E newItem) {
    // We need to override this method, as AnimatedBuilder is not
    // supported as a top-level item widget in reorderable lists.

    final value = updateAnimController.value;

    final oldItem = changes[newItem];
    final item = value < 0.5 ? oldItem : newItem;

    return updateItemBuilder(context, updateAnimation, item);
  }

  // A more complex and less efficient update animation support implementation.
  void _addReorderableUpdateAnimationSupport() {
    bool didUpdateList = false;

    updateAnimController
      ..addListener(() {
        if (updateAnimController.isAnimating) {
          if (!didUpdateList && updateAnimController.value > 0.5) {
            setState(() {});
            didUpdateList = true;
          }

          changes.keys.forEach(buildUpdatedItemWidget);
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          didUpdateList = false;
        }
      });
  }

  @override
  void dispose() {
    _scrollAdjuster?.cancel();
    _controller?.dispose();
    // _itemTranslations.forEach((key, controller) => controller?.dispose());
    super.dispose();
  }
}

// A class that holds meta information about items in the list such as position and size.
class _Item extends Rect implements Comparable<_Item> {
  final RenderBox box;
  final Key key;
  final int index;
  final Offset offset;
  final bool _isVertical;
  _Item(
    this.key,
    this.box,
    this.index,
    this.offset,
    // ignore: avoid_positional_boolean_parameters
    this._isVertical,
  ) : super.fromLTWH(
          offset.dx,
          offset.dy,
          box.size.width,
          box.size.height,
        );

  double get start => _isVertical ? top : left;
  double get end => _isVertical ? bottom : right;
  double get middle => _isVertical ? center.dy : center.dx;

  double distance;

  @override
  int compareTo(_Item other) => distance != null && other.distance != null ? distance.compareTo(other.distance) : -1;

  @override
  String toString() => '_Item key: $key, index: $index';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is _Item && o.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}
