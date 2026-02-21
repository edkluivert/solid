class Task {
  final int id;
  final String title;
  final bool done;

  Task({required this.id, required this.title, this.done = false});

  Task copyWith({bool? done}) =>
      Task(id: id, title: title, done: done ?? this.done);
}
