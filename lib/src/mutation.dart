import 'package:flutter/foundation.dart';

/// Represents the four possible states of a [Mutation].
sealed class MutationState<T> {
  const MutationState();
}

/// The mutation has not been triggered yet.
final class MutationInitial<T> extends MutationState<T> {
  const MutationInitial();
}

/// The mutation is currently executing.
final class MutationLoading<T> extends MutationState<T> {
  const MutationLoading();
}

/// The mutation completed and returned a non-null value.
final class MutationSuccess<T> extends MutationState<T> {
  final T data;
  const MutationSuccess(this.data);
}

/// The mutation completed but returned null (only when [T] is nullable).
final class MutationEmpty<T> extends MutationState<T> {
  const MutationEmpty();
}

/// The mutation failed — either an exception was thrown or an Either Left was returned.
final class MutationError<T> extends MutationState<T> {
  /// The error value.
  /// - Throw-based mutations: the thrown [Object].
  /// - Either-based mutations: the Left value (your `L` type).
  final Object error;
  const MutationError(this.error);
}

// ---------------------------------------------------------------------------
// Mutation<T>
// ---------------------------------------------------------------------------

/// A reactive wrapper around an async function that automatically tracks its
/// lifecycle: `initial → loading → success / empty / error`.
///
/// Create mutations inside your [Solid] ViewModel using the helpers:
///
/// ```dart
/// // Throw-based (exception → error state)
/// late final fetchUser = mutation<User>(() async => userRepo.getUser());
///
/// // Void, throw-based
/// late final logout = mutation<void>(() async => authRepo.logout());
///
/// // Either-based (Left → error, Right → success)
/// late final login = mutationEither<String, User>(
///   () async => authRepo.login(email, pass), // Either<String, User>
/// );
/// ```
///
/// Trigger in the UI:
/// ```dart
/// ElevatedButton(onPressed: vm.fetchUser.call, child: Text('Fetch'))
/// ```
///
/// Observe in the UI with [MutationBuilder].
class Mutation<T> extends ChangeNotifier {
  Mutation._();

  MutationState<T> _state = const _InitialPlaceholder();

  /// The current state of this mutation.
  MutationState<T> get state {
    if (_state is _InitialPlaceholder) _state = MutationInitial<T>();
    return _state;
  }

  // The internal execution function set by the factory helpers.
  late final Future<void> Function() _executeFn;

  void _setState(MutationState<T> next) {
    _state = next;
    notifyListeners();
  }

  /// Triggers the mutation. Calling while already [MutationLoading] is a no-op.
  Future<void> call() => execute();

  /// Triggers the mutation. Alias for [call].
  Future<void> execute() async {
    if (_state is MutationLoading<T>) return;
    _setState(MutationLoading<T>());
    await _executeFn();
  }

  /// Resets this mutation back to [MutationInitial].
  void reset() => _setState(MutationInitial<T>());

  // ── Convenience getters ───────────────────────────────────────────────────

  bool get isInitial => state is MutationInitial<T>;
  bool get isLoading => state is MutationLoading<T>;
  bool get isSuccess => state is MutationSuccess<T>;
  bool get isEmpty => state is MutationEmpty<T>;
  bool get isError => state is MutationError<T>;
}

// Marker used while the typed initial state hasn't been materialised yet.
final class _InitialPlaceholder<T> extends MutationState<T> {
  const _InitialPlaceholder();
}

// ---------------------------------------------------------------------------
// Factory helpers — used by Solid.mutation() and Solid.mutationEither()
// ---------------------------------------------------------------------------

/// Creates a throw-based [Mutation].
///
/// - If [fn] throws → [MutationError] with the exception.
/// - If [fn] returns null (for nullable [T]) → [MutationEmpty].
/// - If [fn] returns a value → [MutationSuccess].
/// - For `Mutation<void>` the return is always [MutationSuccess].
Mutation<T> createMutation<T>(Future<T> Function() fn) {
  final m = Mutation<T>._();
  m._executeFn = () async {
    try {
      final result = await fn();
      m._setState(MutationSuccess<T>(result));
    } catch (e) {
      m._setState(MutationError<T>(e));
    }
  };
  return m;
}

/// Creates an Either-based [Mutation].
///
/// [fn] must return an object compatible with dartz [Either] — i.e. it must
/// expose a `fold(ifLeft, ifRight)` method:
///
/// ```dart
/// late final login = mutationEither<String, User>(
///   () async => authRepo.login(email, pass), // Either<String, User>
/// );
/// ```
///
/// - `Left(l)` → [MutationError] with `l` as the error.
/// - `Right(r)` → [MutationSuccess] (or [MutationEmpty] when r is null).
Mutation<T> createMutationEither<L extends Object, T>(
  Future<dynamic> Function() fn,
) {
  final m = Mutation<T>._();
  m._executeFn = () async {
    try {
      final either = await fn();
      either.fold(
        (dynamic left) => m._setState(MutationError<T>(left as L)),
        (dynamic right) => m._setState(MutationSuccess<T>(right as T)),
      );
    } catch (e) {
      m._setState(MutationError<T>(e));
    }
  };
  return m;
}
