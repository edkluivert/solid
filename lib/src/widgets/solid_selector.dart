import 'package:flutter/widgets.dart';

import '../solid.dart';
import 'solid_provider.dart';

/// Selects a **slice** of state and only rebuilds when that slice changes.
///
/// Use this to avoid unnecessary rebuilds when you only care about a
/// specific part of the state:
///
/// ```dart
/// SolidSelector<CounterViewModel, CounterState, int>(
///   selector: (state) => state.count,
///   builder: (context, count) => Text('$count'),
/// )
/// ```
class SolidSelector<T extends Solid<dynamic>, S, R> extends StatefulWidget {
  /// Extracts the slice of state to watch.
  final R Function(S state) selector;

  /// Called with the selected value whenever it changes.
  final Widget Function(BuildContext context, R value) builder;

  const SolidSelector({
    super.key,
    required this.selector,
    required this.builder,
  });

  @override
  State<SolidSelector<T, S, R>> createState() => _SolidSelectorState<T, S, R>();
}

class _SolidSelectorState<T extends Solid<dynamic>, S, R>
    extends State<SolidSelector<T, S, R>> {
  late T _instance;
  R? _lastSelected;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _instance = SolidProvider.of<T>(context);
    _computeSelected();
    _instance.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(SolidSelector<T, S, R> old) {
    super.didUpdateWidget(old);
    final next = SolidProvider.of<T>(context);
    if (next != _instance) {
      _instance.removeListener(_onChanged);
      _instance = next;
      _computeSelected();
      _instance.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _instance.removeListener(_onChanged);
    super.dispose();
  }

  void _computeSelected() {
    final s = _instance.getOrNull<S>();
    if (s != null) {
      _lastSelected = widget.selector(s);
      _hasValue = true;
    }
  }

  void _onChanged() {
    final s = _instance.getOrNull<S>();
    if (s == null) return;
    final nextSelected = widget.selector(s);
    if (_lastSelected != nextSelected) {
      setState(() {
        _lastSelected = nextSelected;
        _hasValue = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValue) {
      throw StateError('State of type $S has not been initialized. '
          'Call push<$S>() on $T first.');
    }
    return widget.builder(context, _lastSelected as R);
  }
}
