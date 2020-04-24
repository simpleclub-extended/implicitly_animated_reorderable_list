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
  bool nestedInReorder = false;

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList(
      shrinkWrap: true,
      scrollDirection: Axis.horizontal,
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
            return Handle(
              child: Card(
                child: Container(
                  width: 80,
                  color: inDrag ? Colors.grey : null,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(child: Text(item)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
