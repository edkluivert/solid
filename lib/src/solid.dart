import 'package:flutter/foundation.dart';

/// A reactive state management base class for Flutter.
///
/// Supports multiple distinct State types, where each type `S` holds an
/// independent **immutable** state object.
///
/// ```dart
/// class CounterViewModel extends Solid<CounterState> {
///   CounterViewModel() : super(const CounterState());
///
///   void increment() => update((s) => s.copyWith(count: s.count + 1));
/// }
/// ```
abstract class Solid<State> extends ChangeNotifier {
  Solid(State initialState) {
    _states[State] = initialState;
  }

  final Map<Type, dynamic> _states = {};

  /// Retrieves the primary state of this [Solid].
  State get state => get<State>();

  /// Retrieves the current state of type [S].
  ///
  /// Throws a [StateError] if the state has not been initialized via [push].
  S get<S>() {
    if (!_states.containsKey(S)) {
      throw StateError(
          'State of type $S has not been initialized. Call push<$S>() first.');
    }
    return _states[S] as S;
  }

  /// Retrieves the current state of type [S], or null if not yet initialized.
  S? getOrNull<S>() {
    return _states[S] as S?;
  }

  /// Updates the state of type [S] to [newState] and notifies listeners.
  ///
  /// If [newState] is identical to the current state of type [S], no
  /// notification is fired.
  @protected
  void push<S>(S newState) {
    final previous = _states[S];
    if (identical(previous, newState)) return;
    _states[S] = newState;
    onChange(previous, newState);
    notifyListeners();
  }

  /// Convenience method that reads the current primary [state], applies [fn],
  /// and pushes the result.
  ///
  /// ```dart
  /// // Instead of:
  /// push(state.copyWith(count: state.count + 1));
  ///
  /// // Write:
  /// update((s) => s.copyWith(count: s.count + 1));
  /// ```
  @protected
  void update(State Function(State current) fn) => push(fn(state));

  /// Called on every successful [push] **before** listeners are notified.
  ///
  /// Override this for logging, analytics, or debugging:
  ///
  /// ```dart
  /// @override
  /// void onChange(dynamic previous, dynamic next) {
  ///   super.onChange(previous, next);
  ///   debugPrint('$runtimeType: $previous → $next');
  /// }
  /// ```
  @protected
  @mustCallSuper
  void onChange(dynamic previous, dynamic next) {}
}
