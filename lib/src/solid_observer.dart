import 'solid.dart';

/// A record of a single state change, stored in the observer's history.
class SolidChange {
  /// The Solid instance that changed.
  final Solid<dynamic> solid;

  /// The state before the change.
  final dynamic previous;

  /// The state after the change.
  final dynamic next;

  /// When the change occurred.
  final DateTime timestamp;

  SolidChange({
    required this.solid,
    required this.previous,
    required this.next,
  }) : timestamp = DateTime.now();

  @override
  String toString() => '${solid.runtimeType} @ $timestamp: $previous → $next';
}

/// A global observer that receives callbacks for every [Solid] lifecycle event.
///
/// Assign a custom observer to [Solid.observer] to intercept all state changes
/// across your application — useful for logging, analytics, and debugging.
///
/// ```dart
/// class AppObserver extends SolidObserver {
///   @override
///   void onChange(Solid solid, dynamic previous, dynamic next) {
///     super.onChange(solid, previous, next); // records to history
///     debugPrint('${solid.runtimeType}: $previous → $next');
///   }
/// }
///
/// void main() {
///   Solid.observer = AppObserver();
///   runApp(MyApp());
/// }
/// ```
class SolidObserver {
  /// Maximum number of changes to keep in [history].
  ///
  /// Set to 0 to disable history recording.
  int maxHistoryLength;

  /// A ring buffer of recent state changes.
  ///
  /// Available for inspection during debugging or by a future DevTools extension.
  final List<SolidChange> history = [];

  SolidObserver({this.maxHistoryLength = 100});

  /// Called when a new [Solid] instance is created.
  void onCreate(Solid<dynamic> solid) {}

  /// Called on every successful [push], before listeners are notified.
  ///
  /// The default implementation records the change to [history].
  /// Call `super.onChange(...)` in overrides to keep recording.
  void onChange(Solid<dynamic> solid, dynamic previous, dynamic next) {
    if (maxHistoryLength > 0) {
      history.add(SolidChange(solid: solid, previous: previous, next: next));
      if (history.length > maxHistoryLength) {
        history.removeAt(0);
      }
    }
  }

  /// Called when a [Solid] instance is disposed.
  void onDispose(Solid<dynamic> solid) {}
}
