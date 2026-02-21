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
///   listenWhen: (prev, curr) => curr.error != null,
///   buildWhen: (prev, curr) => prev.isLoading != curr.isLoading,
///   listener: (context, state) {
///     if (state.error != null) showSnackBar(state.error!);
///   },
///   builder: (context, state) {
///     if (state.isLoading) return const CircularProgressIndicator();
///     return LoginForm();
///   },
/// )
/// ```
class SolidConsumer<T extends Solid<dynamic>, S> extends StatelessWidget {
  final void Function(BuildContext context, S state) listener;
  final Widget Function(BuildContext context, S state) builder;

  /// Optional filter for the listener. See [SolidListener.listenWhen].
  final bool Function(S previous, S current)? listenWhen;

  /// Optional filter for the builder. See [SolidBuilder.buildWhen].
  final bool Function(S previous, S current)? buildWhen;

  const SolidConsumer({
    super.key,
    required this.listener,
    required this.builder,
    this.listenWhen,
    this.buildWhen,
  });

  @override
  Widget build(BuildContext context) {
    return SolidListener<T, S>(
      listener: listener,
      listenWhen: listenWhen,
      child: SolidBuilder<T, S>(
        builder: builder,
        buildWhen: buildWhen,
      ),
    );
  }
}
