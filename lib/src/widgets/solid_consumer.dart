import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_listener.dart';
import 'solid_builder.dart';

/// Combines [SolidListener] and [SolidBuilder] in a single widget.
///
/// Equivalent to `BlocConsumer` — use when the same state change should
/// both **rebuild the UI** and trigger a **side effect** (snackbar, navigation):
///
/// ```dart
/// SolidConsumer<LoginViewModel, LoginState>(
///   listener: (context, state) {
///     // Fires on every push() — use for navigation, snackbars, etc.
///     if (state.user != null) {
///       Navigator.pushReplacementNamed(context, '/home');
///     }
///   },
///   builder: (context, state) {
///     // Rebuilds the widget on every push()
///     if (state.isLoading) return const CircularProgressIndicator();
///     return LoginForm(onLogin: context.solid<LoginViewModel>().login);
///   },
/// )
/// ```
class SolidConsumer<T extends Solid<dynamic>, S> extends StatelessWidget {
  /// Optional: if null, resolved from the nearest [SolidProvider<T>].
  final T? value;
  final void Function(BuildContext context, S state) listener;
  final Widget Function(BuildContext context, S state) builder;

  const SolidConsumer({
    super.key,
    this.value,
    required this.listener,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return SolidListener<T, S>(
      value: value,
      listener: listener,
      child: SolidBuilder<T, S>(
        value: value,
        builder: builder,
      ),
    );
  }
}
