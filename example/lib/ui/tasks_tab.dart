import 'package:flutter/material.dart';
import 'package:solid_x/solid_x.dart';

import '../tasks_view_model.dart';

class TasksTab extends StatelessWidget {
  const TasksTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidProvider<TasksViewModel>(
      create: TasksViewModel.new,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          centerTitle: true,
          actions: [
            SolidBuilder<TasksViewModel, TasksState>(
              builder: (context, state) {
                final vm = context.solid<TasksViewModel>();
                return IconButton(
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  tooltip: 'Load tasks',
                  onPressed: state.isLoading ? null : vm.loadTasks,
                );
              },
            ),
          ],
        ),
        body: SolidBuilder<TasksViewModel, TasksState>(

          builder: (context, state) {
            final vm = context.solid<TasksViewModel>();
            if (state.tasks.isEmpty && !state.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    const Text('No tasks yet. Tap ↓ to load demo tasks.'),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.tasks.length,
              itemBuilder: (_, i) {
                final task = state.tasks[i];
                return CheckboxListTile(
                  value: task.done,
                  onChanged: (_) => vm.toggleTask(task.id),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  secondary: Icon(
                    task.done
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task.done
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: const _AddTaskFab(),
      ),
    );
  }
}

class _AddTaskFab extends StatefulWidget {
  const _AddTaskFab();

  @override
  State<_AddTaskFab> createState() => _AddTaskFabState();
}

class _AddTaskFabState extends State<_AddTaskFab> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    final vm = context.solid<TasksViewModel>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'New task',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(vm),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _submit(vm),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit(TasksViewModel vm) {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context);
    vm.addTask(title);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _show,
      icon: const Icon(Icons.add),
      label: const Text('Add Task'),
    );
  }
}
