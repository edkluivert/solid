import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solid_x/solid_x.dart';

// =============================================================================
// TEST VIEW-MODELS
// =============================================================================

class _CounterState {
  final int count;
  const _CounterState({this.count = 0});
  _CounterState copyWith({int? count}) =>
      _CounterState(count: count ?? this.count);
}

class _CounterVm extends Solid<_CounterState> {
  _CounterVm() : super(const _CounterState());

  void increment() => push(state.copyWith(count: state.count + 1));
  void decrement() => push(state.copyWith(count: state.count - 1));

  Future<void> asyncIncrement() async {
    await Future<void>.delayed(Duration.zero);
    push(state.copyWith(count: state.count + 1));
  }
}

class _LoginState {
  final bool isLoading;
  final String? user;
  final String? error;
  const _LoginState({this.isLoading = false, this.user, this.error});
  _LoginState copyWith({bool? isLoading, String? user, String? error}) =>
      _LoginState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error ?? this.error,
      );
}

class _LoginVm extends Solid<_LoginState> {
  _LoginVm() : super(const _LoginState());

  Completer<void>? _loginCompleter;

  Future<void> loginOk() async {
    push(state.copyWith(isLoading: true));
    _loginCompleter = Completer<void>();
    await _loginCompleter!.future;
    push(const _LoginState(user: 'demo@test.com'));
  }

  void completeLogin() {
    _loginCompleter?.complete();
  }

  Future<void> loginFail() async {
    push(state.copyWith(isLoading: true));
    await Future.microtask(() {});
    push(const _LoginState(error: 'Invalid credentials'));
  }

  void logout() => push(const _LoginState());
  void setUserDirectly(String user) => push(_LoginState(user: user));
}

class TestSolid extends Solid<int> {
  TestSolid() : super(0) {
    push<String>('initial');
  }

  void increment() => push(state + 1);
  void updateString(String val) => push<String>(val);
}

class _NameVm extends Solid<String> {
  _NameVm() : super('world');
  void setName(String name) => push(name);
}

// Helper ViewModel that tracks disposal
class _TrackingState {
  const _TrackingState();
}

class _TrackingVm extends Solid<_TrackingState> {
  final VoidCallback onDispose;
  _TrackingVm({required this.onDispose}) : super(const _TrackingState());

  @override
  void dispose() {
    onDispose();
    super.dispose();
  }
}

// =============================================================================
// HELPERS
// =============================================================================

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

// =============================================================================
// TESTS
// =============================================================================

void main() {
  group('Solid', () {
    test('holds initial state', () {
      final vm = _CounterVm();
      expect(vm.state.count, equals(0));
      vm.dispose();
    });

    test('push updates state', () {
      final vm = _CounterVm();
      vm.increment();
      expect(vm.state.count, equals(1));
      vm.dispose();
    });

    test('push notifies listeners', () {
      final vm = _CounterVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      vm.increment();
      vm.increment();
      expect(notifyCount, equals(2));
      vm.dispose();
    });

    test('push with new value notifies listeners', () {
      final vm = _NameVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      vm.setName('changed'); // different from initial 'world'
      expect(notifyCount, equals(1));
      vm.dispose();
    });

    test('copyWith creates new state without mutating old', () {
      const s1 = _CounterState(count: 5);
      final s2 = s1.copyWith(count: 10);
      expect(s1.count, equals(5));
      expect(s2.count, equals(10));
    });

    test('logout resets state to initial', () {
      final vm = _LoginVm();
      vm.setUserDirectly('demo@test.com');
      vm.logout();
      expect(vm.state.user, isNull);
      expect(vm.state.isLoading, isFalse);
      vm.dispose();
    });
  });

  group('SolidProvider', () {
    testWidgets('provides vm to descendant via of()', (tester) async {
      _CounterVm? captured;
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>(
          create: _CounterVm.new,
          child: Builder(builder: (ctx) {
            captured = SolidProvider.of<_CounterVm>(ctx);
            return const SizedBox();
          }),
        ),
      ));
      expect(captured, isNotNull);
      expect(captured, isA<_CounterVm>());
    });

    testWidgets('throws when no provider found', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(builder: (ctx) {
          expect(
            () => SolidProvider.of<_CounterVm>(ctx),
            throwsException,
          );
          return const SizedBox();
        }),
      ));
    });

    testWidgets('context.solid<T>() extension works', (tester) async {
      _CounterVm? captured;
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>(
          create: _CounterVm.new,
          child: Builder(builder: (ctx) {
            captured = ctx.solid<_CounterVm>();
            return const SizedBox();
          }),
        ),
      ));
      expect(captured, isA<_CounterVm>());
    });

    testWidgets('disposes vm on removal (create mode)', (tester) async {
      bool disposed = false;
      final vm = _CounterVm();
      vm.addListener(() {});
      final trackVm = _TrackingVm(onDispose: () => disposed = true);

      await tester.pumpWidget(_wrap(
        SolidProvider<_TrackingVm>(
          create: () => trackVm,
          child: const SizedBox(),
        ),
      ));
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(disposed, isTrue);
      vm.dispose();
    });

    testWidgets('value mode does not dispose vm', (tester) async {
      bool disposed = false;
      final trackVm = _TrackingVm(onDispose: () => disposed = true);

      await tester.pumpWidget(_wrap(
        SolidProvider<_TrackingVm>.value(
          value: trackVm,
          child: const SizedBox(),
        ),
      ));
      await tester.pumpWidget(_wrap(const SizedBox()));
      expect(disposed, isFalse);
      trackVm.dispose();
    });

    testWidgets('MultiSolidProvider nests providers', (tester) async {
      _CounterVm? counter;
      _NameVm? name;

      await tester.pumpWidget(_wrap(
        MultiSolidProvider(
          providers: [
            SolidProvider<_CounterVm>(
                create: _CounterVm.new, child: const SizedBox()),
            SolidProvider<_NameVm>(
                create: _NameVm.new, child: const SizedBox()),
          ],
          child: Builder(builder: (ctx) {
            counter = ctx.solid<_CounterVm>();
            name = ctx.solid<_NameVm>();
            return const SizedBox();
          }),
        ),
      ));

      expect(counter, isA<_CounterVm>());
      expect(name, isA<_NameVm>());
    });
  });

  group('SolidBuilder', () {
    testWidgets('renders initial state', (tester) async {
      final vm = _CounterVm();
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>.value(
          value: vm,
          child: SolidBuilder<_CounterVm, _CounterState>(
            builder: (_, state) =>
                Text('${state.count}', textDirection: TextDirection.ltr),
          ),
        ),
      ));
      expect(find.text('0'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('rebuilds when push fires', (tester) async {
      final vm = _CounterVm();
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>.value(
          value: vm,
          child: SolidBuilder<_CounterVm, _CounterState>(
            builder: (_, state) =>
                Text('${state.count}', textDirection: TextDirection.ltr),
          ),
        ),
      ));
      vm.increment();
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('looks up vm from context when value omitted', (tester) async {
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>(
          create: _CounterVm.new,
          child: SolidBuilder<_CounterVm, _CounterState>(
            builder: (context, state) {
              return Text('Count: ${state.count}',
                  textDirection: TextDirection.ltr);
            },
          ),
        ),
      ));
      expect(find.text('Count: 0'), findsOneWidget);
    });
  });

  group('SolidListener', () {
    testWidgets('calls listener on push, does not rebuild', (tester) async {
      final vm = _CounterVm();
      final calls = <int>[];
      int buildCount = 0;

      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>.value(
          value: vm,
          child: SolidListener<_CounterVm, _CounterState>(
            listener: (context, state) => calls.add(state.count),
            child: Builder(builder: (_) {
              buildCount++;
              return const SizedBox();
            }),
          ),
        ),
      ));

      final initialBuilds = buildCount;
      vm.increment();
      await tester.pump();
      vm.increment();
      await tester.pump();

      expect(calls, equals([1, 2]));
      expect(buildCount, equals(initialBuilds)); // no extra rebuilds
      vm.dispose();
    });

    testWidgets('looks up vm from context when value omitted', (tester) async {
      final calls = <int>[];
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>(
          create: _CounterVm.new,
          child: Builder(builder: (ctx) {
            return SolidListener<_CounterVm, _CounterState>(
              listener: (context, state) => calls.add(state.count),
              child: ElevatedButton(
                onPressed: () => ctx.solid<_CounterVm>().increment(),
                child: const Text('tap'),
              ),
            );
          }),
        ),
      ));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(calls, equals([1]));
    });
  });

  group('SolidConsumer', () {
    testWidgets('rebuilds AND calls listener on push', (tester) async {
      final vm = _CounterVm();
      final listenerCalls = <int>[];
      int buildCount = 0;

      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>.value(
          value: vm,
          child: SolidConsumer<_CounterVm, _CounterState>(
            listener: (context, state) => listenerCalls.add(state.count),
            builder: (context, state) {
              buildCount++;
              return Text('${state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ));

      final initialBuilds = buildCount;

      vm.increment();
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(listenerCalls, equals([1]));
      expect(buildCount, greaterThan(initialBuilds));
      vm.dispose();
    });

    testWidgets('looks up vm from context when value omitted', (tester) async {
      final calls = <int>[];
      await tester.pumpWidget(_wrap(
        SolidProvider<_CounterVm>(
          create: _CounterVm.new,
          child: Builder(builder: (ctx) {
            return SolidConsumer<_CounterVm, _CounterState>(
              listener: (context, state) => calls.add(state.count),
              builder: (context, state) =>
                  Text('${state.count}', textDirection: TextDirection.ltr),
            );
          }),
        ),
      ));
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('Async ViewModel patterns', () {
    testWidgets('isLoading state shows during async operation', (tester) async {
      final vm = _LoginVm();
      await tester.pumpWidget(_wrap(
        SolidProvider<_LoginVm>.value(
          value: vm,
          child: SolidBuilder<_LoginVm, _LoginState>(
            builder: (_, state) {
              if (state.isLoading) return const CircularProgressIndicator();
              if (state.user != null)
                return Text('Welcome ${state.user}',
                    textDirection: TextDirection.ltr);
              return const Text('Please login',
                  textDirection: TextDirection.ltr);
            },
          ),
        ),
      ));

      expect(find.text('Please login'), findsOneWidget);

      final future = vm.loginOk();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      vm.completeLogin();
      await future;
      await tester.pump();
      expect(find.text('Welcome demo@test.com'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('error state reflects after failed operation', (tester) async {
      final vm = _LoginVm();
      await tester.pumpWidget(_wrap(
        SolidProvider<_LoginVm>.value(
          value: vm,
          child: SolidBuilder<_LoginVm, _LoginState>(
            builder: (context, state) {
              if (state.error != null)
                return Text('Error: ${state.error}',
                    textDirection: TextDirection.ltr);
              return const Text('ok', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ));

      await vm.loginFail();
      await tester.pump();
      expect(find.text('Error: Invalid credentials'), findsOneWidget);
      vm.dispose();
    });

    testWidgets('logout resets to initial state', (tester) async {
      final vm = _LoginVm()..setUserDirectly('demo@test.com');
      await tester.pumpWidget(
        MaterialApp(
          home: SolidProvider<_LoginVm>.value(
            value: vm,
            child: SolidBuilder<_LoginVm, _LoginState>(
              builder: (context, state) => Text(state.user ?? 'logged out',
                  textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );
      expect(find.text('demo@test.com'), findsOneWidget);

      vm.logout();
      await tester.pump();
      expect(find.text('logged out'), findsOneWidget);
      vm.dispose();
    });
  });

  // ── update() sugar ────────────────────────────────────────────────────────
  group('update()', () {
    test('update applies function and pushes result', () {
      final vm = _UpdateTestVm();
      vm.setCount(42);
      expect(vm.state.count, equals(42));
      vm.dispose();
    });

    test('update notifies listeners', () {
      final vm = _UpdateTestVm();
      int notifyCount = 0;
      vm.addListener(() => notifyCount++);
      vm.setCount(5);
      expect(notifyCount, equals(1));
      vm.dispose();
    });
  });

  // ── onChange() hook ────────────────────────────────────────────────────────
  group('onChange()', () {
    test('onChange is called on push', () {
      final vm = _TrackingChangesVm();
      vm.increment();
      vm.increment();
      expect(vm.changes.length, equals(2));
      expect((vm.changes[0].$1 as _CounterState).count, 0);
      expect((vm.changes[0].$2 as _CounterState).count, 1);
      expect((vm.changes[1].$1 as _CounterState).count, 1);
      expect((vm.changes[1].$2 as _CounterState).count, 2);
      vm.dispose();
    });
  });

  // ── SolidSelector ──────────────────────────────────────────────────────────
  group('SolidSelector', () {
    testWidgets('only rebuilds when selected value changes', (tester) async {
      final vm = _MultiFieldVm();
      int buildCount = 0;

      await tester.pumpWidget(_wrap(
        SolidProvider<_MultiFieldVm>.value(
          value: vm,
          child: SolidSelector<_MultiFieldVm, _MultiFieldState, int>(
            selector: (s) => s.count,
            builder: (context, count) {
              buildCount++;
              return Text('$count', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ));

      final initial = buildCount;
      expect(find.text('0'), findsOneWidget);

      // Change name (count stays the same) — should NOT rebuild
      vm.setName('Alice');
      await tester.pump();
      expect(buildCount, equals(initial));

      // Change count — should rebuild
      vm.incrementCount();
      await tester.pump();
      expect(buildCount, equals(initial + 1));
      expect(find.text('1'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('looks up vm from context when value omitted', (tester) async {
      await tester.pumpWidget(_wrap(
        SolidProvider<_MultiFieldVm>(
          create: _MultiFieldVm.new,
          child: SolidSelector<_MultiFieldVm, _MultiFieldState, String>(
            selector: (s) => s.name,
            builder: (context, name) =>
                Text('Hi $name', textDirection: TextDirection.ltr),
          ),
        ),
      ));
      expect(find.text('Hi world'), findsOneWidget);
    });
  });

  // ── StatusMixin ────────────────────────────────────────────────────────────
  group('StatusMixin', () {
    test('convenience getters work correctly', () {
      const s1 = _StatusState(status: SolidStatus.initial);
      expect(s1.isInitial, isTrue);
      expect(s1.isLoading, isFalse);

      const s2 = _StatusState(status: SolidStatus.loading);
      expect(s2.isLoading, isTrue);
      expect(s2.isSuccess, isFalse);

      const s3 = _StatusState(status: SolidStatus.success);
      expect(s3.isSuccess, isTrue);
      expect(s3.isFailure, isFalse);

      const s4 = _StatusState(
        status: SolidStatus.failure,
        errorMessage: 'oops',
      );
      expect(s4.isFailure, isTrue);
      expect(s4.errorMessage, 'oops');
    });
  });

  // ── SolidObserver ──────────────────────────────────────────────────────────
  group('SolidObserver', () {
    late SolidObserver originalObserver;

    setUp(() {
      originalObserver = Solid.observer;
    });

    tearDown(() {
      Solid.observer = originalObserver;
    });

    test('onCreate is called when Solid is created', () {
      final created = <Type>[];
      Solid.observer = _TestObserver(
        onCreateCb: (s) => created.add(s.runtimeType),
      );
      final vm = _CounterVm();
      expect(created, contains(vm.runtimeType));
      vm.dispose();
    });

    test('onDispose is called when Solid is disposed', () {
      final disposed = <Type>[];
      Solid.observer = _TestObserver(
        onDisposeCb: (s) => disposed.add(s.runtimeType),
      );
      final vm = _CounterVm();
      vm.dispose();
      expect(disposed, contains(vm.runtimeType));
    });

    test('onChange on observer is called on push', () {
      final changes = <(dynamic, dynamic)>[];
      Solid.observer = _TestObserver(
        onChangeCb: (_, prev, next) => changes.add((prev, next)),
      );
      final vm = _CounterVm();
      vm.increment();
      expect(changes.length, equals(1));
      expect((changes[0].$1 as _CounterState).count, 0);
      expect((changes[0].$2 as _CounterState).count, 1);
      vm.dispose();
    });

    test('history records state changes', () {
      final obs = SolidObserver(maxHistoryLength: 50);
      Solid.observer = obs;
      final vm = _CounterVm();
      vm.increment();
      vm.increment();
      expect(obs.history.length, equals(2));
      expect(obs.history[0].toString(), contains('_CounterVm'));
      vm.dispose();
    });

    test('history respects maxHistoryLength', () {
      final obs = SolidObserver(maxHistoryLength: 2);
      Solid.observer = obs;
      final vm = _CounterVm();
      vm.increment();
      vm.increment();
      vm.increment();
      expect(obs.history.length, equals(2)); // oldest dropped
      vm.dispose();
    });
  });

  // ── buildWhen ──────────────────────────────────────────────────────────────
  group('buildWhen', () {
    testWidgets('skips rebuild when buildWhen returns false', (tester) async {
      final vm = _MultiFieldVm();
      int buildCount = 0;

      await tester.pumpWidget(_wrap(
        SolidProvider<_MultiFieldVm>.value(
          value: vm,
          child: SolidBuilder<_MultiFieldVm, _MultiFieldState>(
            buildWhen: (prev, curr) => prev.count != curr.count,
            builder: (_, state) {
              buildCount++;
              return Text('${state.count}', textDirection: TextDirection.ltr);
            },
          ),
        ),
      ));

      final initial = buildCount;

      // Name change — buildWhen returns false, no rebuild
      vm.setName('Alice');
      await tester.pump();
      expect(buildCount, equals(initial));

      // Count change — buildWhen returns true, rebuilds
      vm.incrementCount();
      await tester.pump();
      expect(buildCount, equals(initial + 1));
      expect(find.text('1'), findsOneWidget);
      vm.dispose();
    });
  });

  // ── listenWhen ─────────────────────────────────────────────────────────────
  group('listenWhen', () {
    testWidgets('skips listener when listenWhen returns false', (tester) async {
      final vm = _MultiFieldVm();
      final calls = <int>[];

      await tester.pumpWidget(_wrap(
        SolidProvider<_MultiFieldVm>.value(
          value: vm,
          child: SolidListener<_MultiFieldVm, _MultiFieldState>(
            listenWhen: (prev, curr) => prev.count != curr.count,
            listener: (_, state) => calls.add(state.count),
            child: const SizedBox(),
          ),
        ),
      ));

      // Name change — listenWhen returns false
      vm.setName('Bob');
      await tester.pump();
      expect(calls, isEmpty);

      // Count change — listenWhen returns true
      vm.incrementCount();
      await tester.pump();
      expect(calls, equals([1]));
      vm.dispose();
    });
  });
}

// =============================================================================
// EXTRA TEST HELPERS
// =============================================================================

class _TrackingChangesVm extends Solid<_CounterState> {
  _TrackingChangesVm() : super(const _CounterState());

  final List<(dynamic, dynamic)> changes = [];

  void increment() => update((s) => s.copyWith(count: s.count + 1));

  @override
  void onChange(dynamic previous, dynamic next) {
    super.onChange(previous, next);
    changes.add((previous, next));
  }
}

class _UpdateTestVm extends Solid<_CounterState> {
  _UpdateTestVm() : super(const _CounterState());
  void setCount(int c) => update((s) => s.copyWith(count: c));
}

class _MultiFieldState {
  final int count;
  final String name;
  const _MultiFieldState({this.count = 0, this.name = 'world'});
  _MultiFieldState copyWith({int? count, String? name}) =>
      _MultiFieldState(count: count ?? this.count, name: name ?? this.name);
}

class _MultiFieldVm extends Solid<_MultiFieldState> {
  _MultiFieldVm() : super(const _MultiFieldState());
  void incrementCount() => update((s) => s.copyWith(count: s.count + 1));
  void setName(String n) => update((s) => s.copyWith(name: n));
}

class _StatusState with StatusMixin {
  @override
  final SolidStatus status;
  @override
  final String? errorMessage;

  const _StatusState({
    this.status = SolidStatus.initial,
    this.errorMessage,
  });
}

class _TestObserver extends SolidObserver {
  final void Function(Solid<dynamic> solid)? onCreateCb;
  final void Function(Solid<dynamic> solid, dynamic prev, dynamic next)?
      onChangeCb;
  final void Function(Solid<dynamic> solid)? onDisposeCb;

  _TestObserver({this.onCreateCb, this.onChangeCb, this.onDisposeCb})
      : super(maxHistoryLength: 0);

  @override
  void onCreate(Solid<dynamic> solid) => onCreateCb?.call(solid);

  @override
  void onChange(Solid<dynamic> solid, dynamic previous, dynamic next) {
    super.onChange(solid, previous, next);
    onChangeCb?.call(solid, previous, next);
  }

  @override
  void onDispose(Solid<dynamic> solid) => onDisposeCb?.call(solid);
}
