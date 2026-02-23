import 'package:flutter/material.dart';
import 'package:solid_x/solid_x.dart';

import '../counter_view_model.dart';

class CounterTab extends StatelessWidget {
  const CounterTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidProvider<CounterViewModel>(
      create: CounterViewModel.new,
      child: SolidListener<CounterViewModel, CounterState>(
        listener: (context, state) {
          if (state.count != 0 && state.count % 10 == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Milestone: ${state.count}!'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Counter'), centerTitle: true),
          body: SolidBuilder<CounterViewModel, CounterState>(
            builder: (context, state) {
              final vm = context.solid<CounterViewModel>();
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Count'),
                    // SolidSelector: only rebuilds when count changes,
                    // ignoring isResetting changes entirely.
                    SolidSelector<CounterViewModel, CounterState, int>(
                      selector: (s) => s.count,
                      builder: (context, count) => Text(
                        '$count',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.tonal(
                          onPressed: vm.decrement,
                          child: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.tonal(
                          onPressed: vm.increment,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (state.isResetting)
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Resetting…'),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: vm.resetAsync,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Async Reset'),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
