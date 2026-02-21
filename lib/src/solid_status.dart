/// Built-in status pattern for common loading / success / failure flows.
///
/// Mix [StatusMixin] into your state classes to get convenient getters:
///
/// ```dart
/// class TasksState with StatusMixin {
///   @override
///   final SolidStatus status;
///   @override
///   final String? errorMessage;
///   final List<Task> tasks;
///
///   const TasksState({
///     this.status = SolidStatus.initial,
///     this.errorMessage,
///     this.tasks = const [],
///   });
/// }
/// ```
///
/// Then in your UI:
/// ```dart
/// if (state.isLoading) return const CircularProgressIndicator();
/// if (state.isFailure) return Text('Error: ${state.errorMessage}');
/// ```

/// Represents the status of an async operation.
enum SolidStatus {
  /// No operation has been performed yet.
  initial,

  /// An operation is in progress.
  loading,

  /// The operation completed successfully.
  success,

  /// The operation failed.
  failure,
}

/// Mixin that provides convenient boolean getters on top of [SolidStatus].
///
/// Add `with StatusMixin` to any state class that tracks async status:
///
/// ```dart
/// class MyState with StatusMixin {
///   @override
///   final SolidStatus status;
///   @override
///   final String? errorMessage;
///   // ...
/// }
/// ```
mixin StatusMixin {
  /// The current status of the operation.
  SolidStatus get status;

  /// An optional error message when [status] is [SolidStatus.failure].
  String? get errorMessage;

  /// `true` when [status] is [SolidStatus.initial].
  bool get isInitial => status == SolidStatus.initial;

  /// `true` when [status] is [SolidStatus.loading].
  bool get isLoading => status == SolidStatus.loading;

  /// `true` when [status] is [SolidStatus.success].
  bool get isSuccess => status == SolidStatus.success;

  /// `true` when [status] is [SolidStatus.failure].
  bool get isFailure => status == SolidStatus.failure;
}
