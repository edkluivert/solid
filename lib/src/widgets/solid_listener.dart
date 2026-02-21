import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_provider.dart';

/// Calls [listener] whenever the [Solid] instance pushes a new state of type [S], without rebuilding.
///
/// The nearest [SolidProvider<T>] is used to resolve the ViewModel automatically.
///
/// Use [listenWhen] to filter which state changes trigger the listener:
///
/// ```dart
/// SolidListener<LoginViewModel, LoginState>(
///   listenWhen: (previous, current) => current.error != null,
///   listener: (context, state) {
///     ScaffoldMessenger.of(context).showSnackBar(
///       SnackBar(content: Text(state.error!)),
///     );
///   },
///   child: LoginPage(),
/// )
/// ```
class SolidListener<T extends Solid<dynamic>, S> extends StatefulWidget {
  final Widget child;
  final void Function(BuildContext context, S state) listener;

  /// Optional filter. Return `true` to call listener, `false` to skip.
  /// When null, every state change triggers the listener.
  final bool Function(S previous, S current)? listenWhen;

  const SolidListener({
    super.key,
    required this.listener,
    required this.child,
    this.listenWhen,
  });

  @override
  State<SolidListener<T, S>> createState() => _SolidListenerState<T, S>();
}

class _SolidListenerState<T extends Solid<dynamic>, S>
    extends State<SolidListener<T, S>> {
  late T _instance;
  S? _lastState;

  @override
  void initState() {
    super.initState();
    _instance = SolidProvider.of<T>(context);
    _lastState = _instance.getOrNull<S>();
    _instance.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(SolidListener<T, S> old) {
    super.didUpdateWidget(old);
    final next = SolidProvider.of<T>(context);
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
    if (_lastState != nextState && nextState != null) {
      final previous = _lastState;
      _lastState = nextState;
      if (widget.listenWhen != null &&
          previous != null &&
          !widget.listenWhen!(previous, nextState)) {
        return;
      }
      widget.listener(context, nextState);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
