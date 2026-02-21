import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_provider.dart';

/// Rebuilds [builder] whenever the [Solid] instance pushes a new state of type [S].
///
/// [value] is optional — when omitted, the nearest [SolidProvider<T>] is
/// used automatically. No [Builder] wrapper needed.
///
/// ```dart
/// SolidBuilder<LoginViewModel, LoginState>(
///   builder: (context, state) {
///     if (state.isLoading) return const CircularProgressIndicator();
///     if (state.user != null)  return WelcomeView(user: state.user!);
///     return LoginForm(onLogin: context.solid<LoginViewModel>().login);
///   },
/// )
/// ```
class SolidBuilder<T extends Solid<dynamic>, S> extends StatefulWidget {
  /// Optional: if null, resolved from the nearest [SolidProvider<T>].
  final T? value;
  final Widget Function(BuildContext context, S state) builder;

  const SolidBuilder({super.key, this.value, required this.builder});

  @override
  State<SolidBuilder<T, S>> createState() => _SolidBuilderState<T, S>();
}

class _SolidBuilderState<T extends Solid<dynamic>, S>
    extends State<SolidBuilder<T, S>> {
  late T _instance;
  S? _lastState;

  @override
  void initState() {
    super.initState();
    _instance = widget.value ?? SolidProvider.of<T>(context);
    _lastState = _instance.getOrNull<S>();
    _instance.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(SolidBuilder<T, S> old) {
    super.didUpdateWidget(old);
    final next = widget.value ?? SolidProvider.of<T>(context);
    if (next != _instance) {
      _instance.removeListener(_onChanged);
      _instance = next;
      _lastState = _instance.getOrNull<S>();
      _instance.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final nextState = _instance.getOrNull<S>();
    if (_lastState != nextState) {
      setState(() {
        _lastState = nextState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastState == null) {
      throw StateError(
          'State of type $S has not been initialized. Call push<$S>() on the generic Solid class $T first.');
    }
    return widget.builder(context, _lastState as S);
  }
}
