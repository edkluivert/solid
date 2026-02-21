import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_provider.dart';

/// Calls [listener] whenever the [Solid] instance pushes a new state of type [S], without rebuilding.
///
/// [value] is optional — when omitted the nearest [SolidProvider<T>] is used.
///
/// ```dart
/// SolidListener<LoginViewModel, LoginState>(
///   listener: (context, state) {
///     if (state.error != null) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(content: Text(state.error!)),
///       );
///     }
///   },
///   child: LoginPage(),
/// )
/// ```
class SolidListener<T extends Solid<dynamic>, S> extends StatefulWidget {
  /// Optional: if null, resolved from the nearest [SolidProvider<T>].
  final T? value;
  final Widget child;
  final void Function(BuildContext context, S state) listener;

  const SolidListener({
    super.key,
    this.value,
    required this.listener,
    required this.child,
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
    _instance = widget.value ?? SolidProvider.of<T>(context);
    _lastState = _instance.getOrNull<S>();
    _instance.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(SolidListener<T, S> old) {
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
      _lastState = nextState;
      if (_lastState != null) {
        widget.listener(context, _lastState as S);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
