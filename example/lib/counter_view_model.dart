import 'package:flutter/foundation.dart';
import 'package:solid_x/solid_x.dart';

@immutable
class CounterState {
  final int count;
  final bool isResetting;

  const CounterState({this.count = 0, this.isResetting = false});

  CounterState copyWith({int? count, bool? isResetting}) => CounterState(
    count: count ?? this.count,
    isResetting: isResetting ?? this.isResetting,
  );
}

class CounterViewModel extends Solid<CounterState> {
  CounterViewModel() : super(const CounterState());

  void increment() => update((s) => s.copyWith(count: s.count + 1));

  void decrement() => update((s) => s.copyWith(count: s.count - 1));

  Future<void> resetAsync() async {
    if (state.isResetting) return;
    update((s) => s.copyWith(isResetting: true));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    push(const CounterState()); // back to initial
  }

  /// Demonstrates the onChange lifecycle hook for debugging.
  @override
  void onChange(dynamic previous, dynamic next) {
    super.onChange(previous, next);
    debugPrint('CounterViewModel: $previous → $next');
  }
}
