import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class HorizontalNestedExample extends StatefulWidget {
  const HorizontalNestedExample();

  @override
  State<StatefulWidget> createState() {
    return HorizontalNestedExampleState();
  }
}

class HorizontalNestedExampleState extends State<HorizontalNestedExample> {
  List<String> nestedList = List.generate(20, (i) => "$i");
  GlobalKey nestedListKey = GlobalKey();
  bool nestedInReorder = false;
  ScrollController nestedScrollController;
  Drag nestedDrag;

  @override
  void initState() {
    super.initState();
    nestedScrollController = ScrollController();
  }

  @override
  void dispose() {
    nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Container(
            height: 100,
            child: SingleChildScrollView(
              key: nestedListKey,
              scrollDirection: Axis.horizontal,
              controller: nestedScrollController,
              child: Row(
                children: <Widget>[
                  Card(
                    child: Container(
                        height: 100,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: const Center(child: Text('Sibling Content'))),
                  ),
                  GestureDetector(
                    onHorizontalDragStart: (DragStartDetails details) {
                      nestedDrag = nestedScrollController.position
                          .drag(details, () => nestedDrag = null);
                    },
                    onHorizontalDragUpdate: (DragUpdateDetails details) {
                      if (!nestedInReorder) {
                        nestedDrag.update(details);
                      } else {
                        final RenderBox renderBox = nestedListKey.currentContext
                            .findRenderObject() as RenderBox;
                        final double dragLocalXOffset =
                            renderBox.globalToLocal(details.globalPosition).dx;
                        final ScrollPosition position =
                            nestedScrollController.position;

                        if (dragLocalXOffset < 50 &&
                            position.extentBefore > 0) {
                          final DragUpdateDetails invertedDetails =
                              DragUpdateDetails(
                            sourceTimeStamp: details.sourceTimeStamp,
                            primaryDelta: 10,
                            delta: Offset(10, details.delta.dy),
                            globalPosition: details.globalPosition,
                            localPosition: details.localPosition,
                          );
                          nestedDrag.update(invertedDetails);
                        } else if (dragLocalXOffset >
                                (renderBox.constraints.maxWidth - 50) &&
                            position.extentAfter > 0) {
                          final DragUpdateDetails invertedDetails =
                              DragUpdateDetails(
                            sourceTimeStamp: details.sourceTimeStamp,
                            primaryDelta: -10,
                            delta: Offset(-10, details.delta.dy),
                            globalPosition: details.globalPosition,
                            localPosition: details.localPosition,
                          );
                          nestedDrag.update(invertedDetails);
                        }
                      }
                    },
                    onHorizontalDragCancel: () {
                      nestedDrag?.cancel();
                    },
                    onHorizontalDragEnd: (DragEndDetails details) {
                      nestedDrag?.end(details);
                    },
                    child: ImplicitlyAnimatedReorderableList(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        items: nestedList,
                        areItemsTheSame: (oldItem, newItem) =>
                            oldItem == newItem,
                        onReorderStarted: (item, from) {
                          setState(() {
                            nestedInReorder = true;
                          });
                        },
                        onReorderFinished: (item, from, to, newList) {
                          setState(() {
                            nestedInReorder = false;
                            nestedList
                              ..clear()
                              ..addAll(newList as List<String>);
                          });
                        },
                        itemBuilder: (context, itemAnimation, item, index) {
                          return Reorderable(
                            key: ValueKey(item),
                            builder: (context, dragAnimation, inDrag) {
                              return Handle(
                                controller: nestedScrollController,
                                child: Card(
                                  child: Container(
                                    width: 80,
                                    color: inDrag ? Colors.grey : null,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Center(child: Text(item)),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
