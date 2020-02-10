import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';

import '../animations/animations.dart';
import '../util/util.dart';
import 'search_page.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({
    Key key,
  }) : super(key: key);

  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  static const double _horizontalHeight = 96;

  final List<Language> selectedLanguages = [
    english,
    german,
    spanish,
  ];

  bool inReorder = false;

  void onReorderFinished(List<Language> newItems) {
    setState(() {
      inReorder = false;

      selectedLanguages
        ..clear()
        ..addAll(newItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Languages Demo'),
        backgroundColor: theme.accentColor,
      ),
      body: ListView(
        // Prevent the ListView from scrolling when an item is
        // currently being dragged.
        physics: inReorder ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          _buildVerticalLanguageList(),
          _buildFooter(context, textTheme),
          _buildListSeperator(),
          _buildHorizontalLanguageList(),
        ],
      ),
    );
  }

  // * An example of a vertically reorderable list.
  Widget _buildVerticalLanguageList() {
    return ImplicitlyAnimatedReorderableList<Language>(
      items: selectedLanguages,
      shrinkWrap: true,
      areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
      onReorderStarted: (item, index) => setState(() => inReorder = true),
      onReorderFinished: (movedLanguage, from, to, newItems) {
        // Update the underlying data when the item has been reordered
        onReorderFinished(newItems);
      },
      itemBuilder: (context, itemAnimation, lang, index) {
        return Reorderable(
          key: ValueKey(lang),
          builder: (context, dragAnimation, inDrag) {
            final t = dragAnimation.value;
            final tile = _buildTile(t, lang, index);

            // If the item is in drag, only return the tile as the
            // SizeFadeTransition would clip the shadow.
            if (t > 0.0) {
              return tile;
            }

            // Specifiy an animation to be used.
            return SizeFadeTranstion(
              sizeFraction: 0.7,
              curve: Curves.easeInOut,
              animation: itemAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  tile,
                  Divider(height: 0),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHorizontalLanguageList() {
    return Container(
      height: _horizontalHeight,
      alignment: Alignment.center,
      child: ImplicitlyAnimatedReorderableList<Language>(
        items: selectedLanguages,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        areItemsTheSame: (oldItem, newItem) => oldItem == newItem,
        onReorderFinished: (item, from, to, newItems) => onReorderFinished(newItems),
        itemBuilder: (context, itemAnimation, item, index) {
          return Reorderable(
            key: ValueKey(item.toString()),
            builder: (context, dragAnimation, inDrag) {
              final t = dragAnimation.value;
              final box = buildBox(item, t);

              if (t > 0) return box;

              return SizeFadeTranstion(
                animation: itemAnimation,
                axis: Axis.horizontal,
                axisAlignment: 1.0,
                curve: Curves.ease,
                child: box,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTile(double t, Language lang, int index) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final color = Color.lerp(Colors.white, Colors.grey.shade100, t);
    final elevation = lerpDouble(0, 8, t);

    final List<Widget> actions = selectedLanguages.length > 1
        ? [
            SlideAction(
              closeOnTap: true,
              color: Colors.redAccent,
              onTap: () {
                setState(
                  () => selectedLanguages.remove(lang),
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: textTheme.body2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]
        : [];

    return Slidable(
      actionPane: SlidableBehindActionPane(),
      actions: actions,
      secondaryActions: actions,
      child: Box(
        color: color,
        elevation: elevation,
        child: ListTile(
          title: Text(
            lang.nativeName,
            style: textTheme.bodyText2.copyWith(
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            lang.englishName,
            style: textTheme.bodyText1.copyWith(
              fontSize: 15,
            ),
          ),
          leading: SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: Text(
                '${index + 1}',
                style: textTheme.bodyText2.copyWith(
                  color: theme.accentColor,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          trailing: Handle(
            delay: const Duration(milliseconds: 100),
            child: Icon(
              Icons.list,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBox(Language item, double t) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final elevation = lerpDouble(0, 8, t);

    return Handle(
      delay: const Duration(milliseconds: 500),
      child: Box(
        height: _horizontalHeight,
        width: _horizontalHeight,
        borderRadius: 8,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        elevation: elevation,
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        margin: const EdgeInsets.only(right: 8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                item.nativeName,
                style: textTheme.bodyText2,
              ),
              const SizedBox(height: 8),
              Text(
                item.englishName,
                style: textTheme.bodyText1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, TextTheme textTheme) {
    return Box(
      color: Colors.white,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LanguageSearchPage(),
          ),
        );

        if (result != null && !selectedLanguages.contains(result)) {
          setState(() {
            selectedLanguages.add(result);
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: SizedBox(
              height: 36,
              width: 36,
              child: Center(
                child: Icon(
                  Icons.add,
                  color: Colors.grey,
                ),
              ),
            ),
            title: Text(
              'Add a language',
              style: textTheme.bodyText2.copyWith(
                fontSize: 16,
              ),
            ),
          ),
          Divider(height: 0),
        ],
      ),
    );
  }

  Widget _buildListSeperator() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    Widget buildDivider() => Container(
          height: 2,
          color: Colors.grey.shade300,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        buildDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'Horizontally',
            style: textTheme.bodyText2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        buildDivider(),
        const SizedBox(height: 16),
      ],
    );
  }
}
