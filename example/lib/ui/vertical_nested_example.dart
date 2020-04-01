import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class VerticalNestedExample extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return VerticalNestedExampleState();
  }
}

class VerticalNestedExampleState extends State<VerticalNestedExample> {
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
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            key: nestedListKey,
            controller: nestedScrollController,
            physics:
                nestedInReorder ? const NeverScrollableScrollPhysics() : null,
            child: Column(
              children: <Widget>[
                Card(
                  child: Container(
                      height: 60,
                      child: const Center(child: Text('Sibling Content'))),
                ),
                GestureDetector(
                  onVerticalDragStart: (DragStartDetails details) {
                    nestedDrag = nestedScrollController.position
                        .drag(details, () => nestedDrag = null);
                  },
                  onVerticalDragUpdate: (DragUpdateDetails details) {
                    if (!nestedInReorder) {
                      nestedDrag.update(details);
                    } else {
                      final RenderBox renderBox = nestedListKey.currentContext
                          .findRenderObject() as RenderBox;
                      final double dragLocalYOffset =
                          renderBox.globalToLocal(details.globalPosition).dy;
                      final ScrollPosition position =
                          nestedScrollController.position;

                      if (dragLocalYOffset < 50 && position.extentBefore > 0) {
                        final DragUpdateDetails invertedDetails =
                            DragUpdateDetails(
                          sourceTimeStamp: details.sourceTimeStamp,
                          primaryDelta: 10,
                          delta: Offset(details.delta.dx, 10),
                          globalPosition: details.globalPosition,
                          localPosition: details.localPosition,
                        );
                        nestedDrag.update(invertedDetails);
                      } else if (dragLocalYOffset >
                              (renderBox.constraints.maxHeight - 50) &&
                          position.extentAfter > 0) {
                        final DragUpdateDetails invertedDetails =
                            DragUpdateDetails(
                          sourceTimeStamp: details.sourceTimeStamp,
                          primaryDelta: -10,
                          delta: Offset(details.delta.dx, -10),
                          globalPosition: details.globalPosition,
                          localPosition: details.localPosition,
                        );
                        nestedDrag.update(invertedDetails);
                      }
                    }
                  },
                  onVerticalDragCancel: () {
                    nestedDrag?.cancel();
                  },
                  onVerticalDragEnd: (DragEndDetails details) {
                    nestedDrag?.end(details);
                  },
                  child: ImplicitlyAnimatedReorderableList(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      items: nestedList,
                      areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
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
                            return Card(
                              child: Container(
                                height: 60,
                                color: inDrag ? Colors.grey : null,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Center(child: Text(item)),
                                    Handle(
                                      controller: nestedScrollController,
                                      child: Icon(Icons.menu),
                                    )
                                  ],
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
        )
      ],
    );
  }
}
