import 'package:flutter/foundation.dart';
import 'package:solid_x/solid_x.dart';

import 'task.dart';

@immutable
class TasksState with StatusMixin {
  @override
  final SolidStatus status;
  @override
  final String? errorMessage;
  final List<Task> tasks;

  const TasksState({
    this.status = SolidStatus.initial,
    this.errorMessage,
    this.tasks = const [],
  });

  TasksState copyWith({
    SolidStatus? status,
    List<Task>? tasks,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TasksState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TasksViewModel extends Solid<TasksState> {
  TasksViewModel() : super(const TasksState());

  int _nextId = 4;

  Future<void> loadTasks() async {
    push(state.copyWith(status: SolidStatus.loading, clearError: true));
    await Future<void>.delayed(const Duration(seconds: 1));
    push(
      TasksState(
        status: SolidStatus.success,
        tasks: [
          Task(id: 1, title: 'Buy groceries'),
          Task(id: 2, title: 'Learn Solid state management'),
          Task(id: 3, title: 'Build something awesome'),
        ],
      ),
    );
  }

  void toggleTask(int id) {
    push(
      state.copyWith(
        tasks: state.tasks
            .map((t) => t.id == id ? t.copyWith(done: !t.done) : t)
            .toList(),
      ),
    );
  }

  Future<void> addTask(String title) async {
    push(state.copyWith(status: SolidStatus.loading));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final task = Task(id: _nextId++, title: title);
    push(
      state.copyWith(
        status: SolidStatus.success,
        tasks: [...state.tasks, task],
      ),
    );
  }
}
