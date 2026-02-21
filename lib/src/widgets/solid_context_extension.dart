import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_provider.dart';

/// Convenience extensions on [BuildContext].
extension SolidContext on BuildContext {
  /// Returns the nearest [T] provided by a [SolidProvider<T>].
  ///
  /// Works with both [Solid] and other [ChangeNotifier]s.
  /// Call from any descendant widget's `build` method or `initState`.
  ///
  /// ```dart
  /// final vm = context.solid<LoginViewModel>();
  /// ```
  T solid<T extends ChangeNotifier>() => SolidProvider.of<T>(this);
}
