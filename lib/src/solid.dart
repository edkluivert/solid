import 'package:flutter/foundation.dart';

import 'mutation.dart';
import 'solid_observer.dart';

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
  /// Global observer that receives lifecycle callbacks for every [Solid].
  ///
  /// ```dart
  /// Solid.observer = AppObserver();
  /// ```
  static SolidObserver observer = SolidObserver();

  Solid(State initialState) {
    _states[State] = initialState;
    Solid.observer.onCreate(this);
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
    Solid.observer.onChange(this, previous, newState);
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
  /// Override this for per-instance logging, analytics, or debugging:
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

  // ── Mutation helpers ────────────────────────────────────────────────────

  /// Creates a throw-based [Mutation] owned by this ViewModel.
  ///
  /// ```dart
  /// late final fetchUser = mutation<User>(() async => repo.getUser());
  /// late final logout    = mutation<void>(() async => repo.logout());
  /// ```
  ///
  /// If [fn] throws, the mutation transitions to [MutationError].
  @protected
  Mutation<T> mutation<T>(Future<T> Function() fn) => createMutation<T>(fn);

  /// Creates an Either-based [Mutation] owned by this ViewModel.
  ///
  /// ```dart
  /// late final login = mutationEither<String, User>(
  ///   () async => repo.login(email, pass), // Either<String, User>
  /// );
  /// ```
  ///
  /// - `Left(l)` → [MutationError] with `l` as the typed error.
  /// - `Right(r)` → [MutationSuccess] (or [MutationEmpty] when r is null).
  @protected
  Mutation<T> mutationEither<L extends Object, T>(
    Future<dynamic> Function() fn,
  ) =>
      createMutationEither<L, T>(fn);

  @override
  void dispose() {
    Solid.observer.onDispose(this);
    super.dispose();
  }
}
