import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class VerticalNestedExample extends StatefulWidget {
  const VerticalNestedExample();

  @override
  State<StatefulWidget> createState() {
    return VerticalNestedExampleState();
  }
}

class VerticalNestedExampleState extends State<VerticalNestedExample> {
  List<String> nestedList = List.generate(20, (i) => "$i");
  bool nestedInReorder = false;

  @override
  Widget build(BuildContext context) {
    return ImplicitlyAnimatedReorderableList(
      shrinkWrap: true,
      items: nestedList,
      areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
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
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Center(child: Text(item)),
                    Handle(
                      child: Icon(Icons.menu),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
