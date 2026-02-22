# solid_x

A lightweight, reactive state management library for Flutter.

Inspired by Kotlin's `ViewModel + StateFlow` pattern, Solid provides a clean architecture to manage your application's state with zero code generation and zero boilerplate. Under the hood, **Solid is powered entirely by Flutter's native `ChangeNotifier`**, making it lightweight and incredibly efficient.

## Features

- **`Solid<State>`** – extend this base class to define your business logic with a typed `.state` getter, just like Cubit.
- **`push(state)`** – updates state and notifies listeners only when it actually changes.
- **`update((s) => ...)`** – sugar that reads the current state, applies your function, and pushes.
- **`onChange(previous, next)`** – overridable lifecycle hook for logging and debugging.
- **Multi-state** – a single `Solid` can manage multiple independent state types with `push<S>()` and `get<S>()`.
- **`Mutation<T>`** – declare async functions that auto-track `initial → loading → success / error / empty` with zero boilerplate.
- **7 widgets** – `SolidProvider`, `SolidBuilder`, `SolidListener`, `SolidConsumer`, `SolidSelector`, `MutationBuilder`, and `context.solid<T>()`.
- **`SolidStatus` + `StatusMixin`** – opt-in enum for standardized loading/success/failure patterns.
- **Powered by `ChangeNotifier`** – zero hidden magic.

---

## Installation

```yaml
# pubspec.yaml
dependencies:
  solid_x:
    git:
      url: https://github.com/edkluivert/solid
```

---

## Quick Start

### 1. Define your State
Create an immutable class to hold all state for your feature.

```dart
class CounterState {
  final int count;
  final bool isResetting;

  const CounterState({this.count = 0, this.isResetting = false});

  CounterState copyWith({int? count, bool? isResetting}) => CounterState(
        count: count ?? this.count,
        isResetting: isResetting ?? this.isResetting,
      );
}
```

### 2. Define your ViewModel
Extend `Solid<State>` and use `push()` or `update()` to change state. You get a natively typed `.state` getter, just like Cubit.

```dart
class CounterViewModel extends Solid<CounterState> {
  CounterViewModel() : super(const CounterState());

  // update() reads state, applies fn, and pushes the result
  void increment() => update((s) => s.copyWith(count: s.count + 1));

  void decrement() => update((s) => s.copyWith(count: s.count - 1));

  Future<void> resetAsync() async {
    if (state.isResetting) return;
    push(state.copyWith(isResetting: true));
    await Future.delayed(const Duration(milliseconds: 600));
    push(const CounterState());
  }

  // Optional: lifecycle hook for debugging
  @override
  void onChange(dynamic previous, dynamic next) {
    super.onChange(previous, next);
    debugPrint('$runtimeType: $previous → $next');
  }
}
```

### 3. (Optional) Manage Multiple States
A single `Solid` can manage multiple independent state objects. Your primary state is typed via the generic, while secondary states use explicit type arguments:

```dart
class LoginViewModel extends Solid<LoginState> {
  LoginViewModel() : super(const LoginState()) {
    push(const LoginFormState()); // secondary state
  }

  // These act like Bloc events — no controllers needed
  void emailChanged(String value) =>
      push(get<LoginFormState>().copyWith(email: value));

  void passwordChanged(String value) =>
      push(get<LoginFormState>().copyWith(password: value));

  Future<void> login() async { ... }
}
```

In your UI, specify which state to listen to:
```dart
// Rebuilds ONLY when LoginFormState changes
SolidBuilder<LoginViewModel, LoginFormState>(
  builder: (context, form) => FilledButton(
    onPressed: form.isValid ? vm.login : null,
    child: const Text('Sign in'),
  ),
)
```

### 4. Provide it
Use `SolidProvider` to make the ViewModel available to the widget tree.

```dart
SolidProvider<CounterViewModel>(
  create: CounterViewModel.new,
  child: CounterView(),
)
```

### 5. Use it in your UI

```dart
class CounterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SolidConsumer<CounterViewModel, CounterState>(
      listener: (context, state) {
        if (state.count == 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reached 10!')),
          );
        }
      },
      builder: (context, state) {
        if (state.isResetting) return const CircularProgressIndicator();

        return Column(
          children: [
            // SolidSelector: only rebuilds when count changes
            SolidSelector<CounterViewModel, CounterState, int>(
              selector: (s) => s.count,
              builder: (context, count) => Text('Count: $count'),
            ),
            ElevatedButton(
              onPressed: context.solid<CounterViewModel>().increment,
              child: const Text('Increment'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Mutation

`Mutation<T>` lets you declare async functions directly in your ViewModel that automatically track their full lifecycle — no manual `isLoading`, `error`, or `data` fields needed.

### Declaring mutations

```dart
class AuthViewModel extends Solid<AuthState> {
  AuthViewModel() : super(const AuthState());

  // Throw-based — exception becomes the error state
  late final fetchUser = mutation<User>(() async => userRepo.getUser());

  // Void throw-based — no return value, still tracks loading/error
  late final logout = mutation<void>(() async => authRepo.logout());

  // Either-based — Left becomes error, Right becomes success
  // Compatible with dartz Either<L, R> or any object with fold()
  late final login = mutationEither<String, User>(
    () async => authRepo.login(email, password), // Either<String, User>
  );
}
```

### Rendering mutations in the UI

```dart
MutationBuilder<User>(
  mutation: vm.fetchUser,

  initial: (ctx) => TextButton(
    onPressed: vm.fetchUser.call, // trigger the mutation
    child: const Text('Load User'),
  ),
  loading: (ctx) => const CircularProgressIndicator(),
  success: (ctx, user) => Text('Hello ${user.name}'),
  error:   (ctx, e)    => Text('Failed: $e'),
  empty:   (ctx)       => const Text('No user found'), // optional

  // Side-effect hooks (don't rebuild, just fire once)
  onSuccess: (ctx, user) => Navigator.pushNamed(ctx, '/home'),
  onError:   (ctx, e)    => ScaffoldMessenger.of(ctx).showSnackBar(...),

  // Optional rebuild filter
  buildWhen: (prev, curr) => curr is! MutationLoading,
)
```

### Void mutations

For `mutation<void>`, the `success` callback receives a `_` (ignored) parameter:

```dart
MutationBuilder<void>(
  mutation: vm.logout,
  initial: (ctx) => TextButton(onPressed: vm.logout.call, child: const Text('Logout')),
  loading: (ctx) => const CircularProgressIndicator(),
  success: (ctx, _) => const Text('Signed out'),
  error:   (ctx, e) => Text('Error: $e'),
)
```

### Mutation state lifecycle

```
initial ──.call()──▶ loading ──▶ success(data)
                             ├──▶ empty          ← null return
                             └──▶ error(e)       ← thrown / Left
```

Use `.reset()` to return a mutation to `initial`:
```dart
TextButton(onPressed: vm.fetchUser.reset, child: const Text('Reset'))
```

---

## Widget Reference

| Widget | Purpose | Bloc Equivalent |
|---|---|---|
| `SolidProvider<T>` | Provide & auto-dispose a ViewModel | `BlocProvider` |
| `SolidBuilder<T, S>` | Rebuild UI when state `S` changes | `BlocBuilder` |
| `SolidListener<T, S>`| Side effects (navigation, snackbars) | `BlocListener` |
| `SolidConsumer<T, S>`| Builder + listener combined | `BlocConsumer` |
| `SolidSelector<T, S, R>`| Rebuild only when a **slice** of state changes | `BlocSelector` |
| `MutationBuilder<T>` | Render per-state UI for a `Mutation<T>` | — |

Access the ViewModel directly with `context.solid<T>()`:
```dart
final vm = context.solid<CounterViewModel>();
vm.increment();
```

---

## SolidStatus (Optional)

Mix `StatusMixin` into your state class for standardized loading/success/failure:

```dart
class TasksState with StatusMixin {
  @override
  final SolidStatus status;
  @override
  final String? errorMessage;
  final List<Task> tasks;

  const TasksState({
    this.status = SolidStatus.initial,
    this.errorMessage,
    this.tasks = const [],
  });
}
```

Then use `state.isLoading`, `state.isSuccess`, `state.isFailure` anywhere.

---

## Filtering Rebuilds & Side Effects

Use `buildWhen` and `listenWhen` to control exactly when widgets rebuild or fire:

```dart
SolidConsumer<LoginViewModel, LoginState>(
  // Only rebuild when loading state changes
  buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
  // Only fire listener when there's a new error
  listenWhen: (prev, curr) => curr.error != null && prev.error != curr.error,
  listener: (context, state) => showSnackBar(state.error!),
  builder: (context, state) {
    if (state.isLoading) return const CircularProgressIndicator();
    return LoginForm();
  },
)
```

---

## SolidObserver

A global observer that receives lifecycle callbacks for **every** `Solid` instance — similar to `Bloc.observer`:

```dart
class AppObserver extends SolidObserver {
  @override
  void onCreate(Solid solid) => debugPrint('Created: ${solid.runtimeType}');

  @override
  void onChange(Solid solid, dynamic previous, dynamic next) {
    super.onChange(solid, previous, next); // records to history
    debugPrint('${solid.runtimeType}: $previous → $next');
  }

  @override
  void onDispose(Solid solid) => debugPrint('Disposed: ${solid.runtimeType}');
}

void main() {
  Solid.observer = AppObserver();
  runApp(MyApp());
}
```

The observer also maintains a **state timeline** via `Solid.observer.history` — a ring buffer of recent `SolidChange` records, ready for a future DevTools extension.

---

## Example

See the [`example/`](example/) directory for a full five-tab demo showcasing Counter, Tasks, Auth (login/logout with multi-state form validation), Cart, and **Mutation** (all mutation variants with live error simulation).
