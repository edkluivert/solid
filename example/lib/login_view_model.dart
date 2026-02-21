import 'package:flutter/foundation.dart';
import 'package:solid/solid.dart';

import 'user.dart';

@immutable
class LoginState {
  final bool isLoading;
  final User? user;
  final String? error;

  const LoginState({this.isLoading = false, this.user, this.error});

  LoginState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  String toString() =>
      'LoginState(isLoading: $isLoading, user: $user, error: $error)';
}

/// Secondary state that tracks form field values and validation.
/// This is the multi-state demo: one Solid manages both
/// [LoginState] (primary) and [LoginFormState] (secondary).
@immutable
class LoginFormState {
  final String email;
  final String password;
  final bool isValid;

  const LoginFormState({
    this.email = '',
    this.password = '',
    this.isValid = false,
  });

  LoginFormState copyWith({String? email, String? password}) {
    final e = email ?? this.email;
    final p = password ?? this.password;
    return LoginFormState(
      email: e,
      password: p,
      isValid: e.isNotEmpty && e.contains('@') && p.isNotEmpty,
    );
  }
}

class LoginViewModel extends Solid<LoginState> {
  LoginViewModel() : super(const LoginState()) {
    // Initialize the secondary form state
    push(const LoginFormState());
  }

  // ── Form "events" — equivalent to Bloc events ──

  void emailChanged(String value) {
    push(get<LoginFormState>().copyWith(email: value));
  }

  void passwordChanged(String value) {
    push(get<LoginFormState>().copyWith(password: value));
  }

  // ── Actions ──

  Future<void> login() async {
    final form = get<LoginFormState>();
    push(state.copyWith(isLoading: true, clearError: true));

    await Future<void>.delayed(const Duration(seconds: 1));

    if (form.email == 'demo@solid.dev' && form.password == 'password') {
      push(
        state.copyWith(
          user: User(name: 'Demo User', email: form.email),
        ),
      );
    } else {
      push(
        state.copyWith(
          isLoading: false,
          error: 'Invalid credentials. Use demo@solid.dev / password',
        ),
      );
    }
  }

  void logout() => push(const LoginState());
}
