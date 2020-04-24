import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'handler.dart';
export 'invisible.dart';
export 'key_extensions.dart';

void ifTrue(bool condition, Function callback) {
  if (condition) callback();
}

void postFrame(VoidCallback callback) => WidgetsBinding.instance.addPostFrameCallback((_) => callback());

extension ListExtension<E> on List<E> {
  E getOrNull(int index) => index < length ? this[index] : null;

  E get firstOrNull => isNotEmpty ? first : null; 
}

extension NumExtension<T extends num> on T {
  bool isBetween(T min, T max) => this >= min && this <= max;

  T atLeast(T min) => math.max(this, min);
  T atMost(T max) => math.min(this, max);
}
