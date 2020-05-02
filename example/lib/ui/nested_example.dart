import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class VerticalNestedExample extends StatefulWidget {
  const VerticalNestedExample();

  @override
  State<StatefulWidget> createState() => VerticalNestedExampleState();
}

class VerticalNestedExampleState extends State<VerticalNestedExample> {
  List<String> nestedList = List.generate(20, (i) => "$i");
  bool nestedInReorder = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
      ),
      body: ImplicitlyAnimatedReorderableList<String>(
        shrinkWrap: true,
        items: nestedList,
        areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
        onReorderFinished: (item, from, to, newList) {
          setState(() {
            nestedList
              ..clear()
              ..addAll(newList);
          });
        },
        header: Container(
          height: 120,
          color: Colors.red,
          child: Center(
            child: Text(
              'Header',
              style: textTheme.headline6.copyWith(color: Colors.white),
            ),
          ),
        ),
        footer: Container(
          height: 120,
          color: Colors.red,
          child: Center(
            child: Text(
              'Footer',
              style: textTheme.headline6.copyWith(color: Colors.white),
            ),
          ),
        ),
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
            key: ValueKey(item),
            child: Card(
              child: Handle(
                delay: const Duration(milliseconds: 250),
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(item),
                      Icon(Icons.menu),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
