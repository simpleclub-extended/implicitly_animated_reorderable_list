import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/src/diff/myers_diff.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

void main() => runApp(FirebaseTest());

class A {
  final int id;
  final String title;
  A(this.id, this.title);
}

class FirebaseTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Firebase test',
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  const Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('todos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();

        final todos = snapshot.data.documents.map(Todo.fromSnapshot).toList();
        return _buildList(context, todos);
      },
    );
  }

  Widget _buildList(BuildContext context, List<Todo> todos) {
    return ImplicitlyAnimatedReorderableList<Todo>(
      items: todos,
      areItemsTheSame: (oldItem, newItem) => oldItem.id == newItem.id,
      itemBuilder: (context, animation, todo, index) {
        return Reorderable(
          key: ValueKey(todo),
          builder: (context, dragAnimation, _) {
            return SizeFadeTransition(
              animation: animation,
              child: AnimatedOpacity(
                opacity: todo.done ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 1000),
                child: Handle(
                  delay: const Duration(milliseconds: 250),
                  child: CheckboxListTile(
                    value: todo.done,
                    title: Text(todo.title),
                    onChanged: (value) => todo.ref.updateData({'done': value}),
                  ),
                ),
              ),
            );
          },
        );
      },
      onReorderFinished: (_, from, to, newTodos) async {
        final todoRef = Firestore.instance.collection('todos');

        for (final todo in todos) {
          await todo.ref.delete();
        }

        for (final todo in newTodos) {
          await todoRef.document(todo.id).setData(todo.toMap());
        }
      },
    );
  }
}

class Todo {
  final String title;
  final bool done;
  final DocumentReference ref;
  Todo({
    this.title = '',
    this.done = false,
    this.ref,
  });

  String get id => ref.documentID;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'done': done,
    };
  }

  static Todo fromSnapshot(DocumentSnapshot snapshot) {
    final map = snapshot.data;

    return Todo(
      ref: snapshot.reference,
      title: map['title'] ?? '',
      done: map['done'] ?? false,
    );
  }

  @override
  String toString() => 'Todo(title: $title, done: $done)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Todo && o.title == title && o.done == done;
  }

  @override
  int get hashCode => title.hashCode ^ done.hashCode;
}
