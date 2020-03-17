import 'package:example/util/box.dart';
import 'package:flutter/material.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

class TestPage extends StatefulWidget {
  const TestPage({Key key}) : super(key: key);

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  List<Color> colors = List.from(Colors.accents);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ImplicitlyAnimatedReorderableList<Color>(
        items: colors,
        itemBuilder: buildItem,
        areItemsTheSame: (oldItem, newItem) => oldItem.value == newItem.value,
        onReorderFinished: (item, from, to, newItems) {
          setState(() {
            colors = List.from(newItems);
          });
        },
      ),
    );
  }

  Reorderable buildItem(BuildContext context, Animation itemAnimation, Color color, int index) {
    return Reorderable(
      key: ValueKey(color),
      builder: (context, dragAnimation, _) {
        return Handle(
          delay: const Duration(milliseconds: 50),
          child: Box(
            color: color,
            height: 56,
            width: double.infinity,
            border: const Border.symmetric(
              vertical: BorderSide(
                color: Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }
}
