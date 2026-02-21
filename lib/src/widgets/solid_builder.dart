import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_provider.dart';

/// Rebuilds [builder] whenever the [Solid] instance pushes a new state of type [S].
///
/// The nearest [SolidProvider<T>] is used to resolve the ViewModel automatically.
///
/// Use [buildWhen] to filter which state changes trigger a rebuild:
///
/// ```dart
/// SolidBuilder<CounterViewModel, CounterState>(
///   buildWhen: (previous, current) => previous.count != current.count,
///   builder: (context, state) => Text('${state.count}'),
/// )
/// ```
class SolidBuilder<T extends Solid<dynamic>, S> extends StatefulWidget {
  final Widget Function(BuildContext context, S state) builder;

  /// Optional filter. Return `true` to rebuild, `false` to skip.
  /// When null, every state change triggers a rebuild.
  final bool Function(S previous, S current)? buildWhen;

  const SolidBuilder({
    super.key,
    required this.builder,
    this.buildWhen,
  });

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
    _instance = SolidProvider.of<T>(context);
    _lastState = _instance.getOrNull<S>();
    _instance.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(SolidBuilder<T, S> old) {
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
    if (_lastState != nextState) {
      final previous = _lastState;
      if (widget.buildWhen != null &&
          previous != null &&
          nextState != null &&
          !widget.buildWhen!(previous, nextState)) {
        _lastState = nextState;
        return;
      }
      setState(() {
        _lastState = nextState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_lastState == null) {
      throw StateError(
          'State of type $S has not been initialized. Call push<$S>() on $T first.');
    }
    return widget.builder(context, _lastState as S);
  }
}
