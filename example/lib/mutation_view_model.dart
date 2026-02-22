import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:solid_x/solid_x.dart';

import 'user.dart';

// ---------------------------------------------------------------------------
// Fake repo — simulates network latency + random failures
// ---------------------------------------------------------------------------

class _FakeRepo {
  final _rng = Random();

  /// Always returns a user (35% chance of throwing).
  Future<User> fetchUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (_rng.nextDouble() < 0.35) throw Exception('Network error: timeout');
    return User(name: 'Ada Lovelace', email: 'ada@solid.dev');
  }

  /// Returns a list — 50% chance of empty list, 20% chance of throwing.
  Future<List<User>> fetchTeam() async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (_rng.nextDouble() < 0.20) throw Exception('Server error: 500');
    if (_rng.nextDouble() < 0.50) return []; // empty result
    return [
      User(name: 'Ada Lovelace', email: 'ada@solid.dev'),
      User(name: 'Grace Hopper', email: 'grace@solid.dev'),
    ];
  }

  /// Void — no return, 35% chance of throwing.
  Future<void> deleteUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (_rng.nextDouble() < 0.35) {
      throw Exception('Delete failed: permission denied');
    }
  }

  /// Either-based login.
  Future<_Either<String, User>> loginEither(String email, String pass) async {
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (email == 'demo@solid.dev' && pass == 'password') {
      return _Either.right(User(name: 'Demo User', email: email));
    }
    return const _Either.left('Wrong email or password');
  }
}

// ---------------------------------------------------------------------------
// Minimal Either (no dartz dependency needed)
// ---------------------------------------------------------------------------

class _Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isLeft;

  const _Either.left(L left) : _left = left, _right = null, _isLeft = true;

  const _Either.right(R right) : _right = right, _left = null, _isLeft = false;

  C fold<C>(C Function(L) ifLeft, C Function(R) ifRight) =>
      _isLeft ? ifLeft(_left as L) : ifRight(_right as R);
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

@immutable
class MutationDemoState {
  const MutationDemoState();
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

class MutationViewModel extends Solid<MutationDemoState> {
  MutationViewModel() : super(const MutationDemoState());

  final _repo = _FakeRepo();

  // 1. Throw-based, returns data — demos listener + listenWhen
  late final fetchUser = mutation<User>(() => _repo.fetchUser());

  // 2. List-returning — demos emptyWhen
  late final fetchTeam = mutation<List<User>>(() => _repo.fetchTeam());

  // 3. Void throw-based — demos no-return mutations
  late final deleteUser = mutation<void>(() => _repo.deleteUser());

  // 4. Either-based — demos typed error (Left = String, Right = User)
  late final loginEither = mutationEither<String, User>(
    () => _repo.loginEither('demo@solid.dev', 'password'),
  );

  // Always-fail version
  late final loginEitherFail = mutationEither<String, User>(
    () => _repo.loginEither('wrong@email.com', 'bad'),
  );
}
