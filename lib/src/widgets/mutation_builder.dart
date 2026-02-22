import 'package:flutter/widgets.dart';

import '../mutation.dart';

/// Builds a widget tree that reflects the current [MutationState] of a
/// [Mutation], optionally fires side-effect callbacks, and supports a
/// user-defined "empty" condition.
///
/// ```dart
/// MutationBuilder<List<Post>>(
///   mutation: vm.fetchPosts,
///
///   // YOU decide what counts as empty
///   emptyWhen: (posts) => posts.isEmpty,
///
///   // Full listener for any state transition
///   listener: (ctx, state) {
///     if (state is MutationLoading) showTopLoader(ctx);
///   },
///   listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
///
///   initial: (ctx)        => FetchButton(onTap: vm.fetchPosts.call),
///   loading: (ctx)        => const CircularProgressIndicator(),
///   success: (ctx, posts) => PostList(posts: posts),
///   empty:   (ctx)        => const Text('No posts yet'),
///   error:   (ctx, e)     => Text('Error: $e'),
/// )
/// ```
///
/// ### Empty state
///
/// [emptyWhen] receives the successful data and returns `true` if the result
/// should be treated as empty. When true, [empty] is rendered instead of
/// [success]. If [emptyWhen] is null, [empty] is never rendered.
///
/// ```dart
/// emptyWhen: (posts) => posts.isEmpty,  // List
/// emptyWhen: (user)  => user == null,   // nullable T
/// emptyWhen: (text)  => text.isEmpty,   // String
/// ```
///
/// ### Listener + listenWhen
///
/// [listener] fires as a side effect on every state change (or when
/// [listenWhen] returns true). Use it for navigation, snackbars, analytics,
/// or any effect you'd normally put in [SolidListener]:
///
/// ```dart
/// listener: (ctx, state) {
///   if (state is MutationSuccess<User>) Navigator.pushNamed(ctx, '/home');
///   if (state is MutationError)         showSnackBar(ctx, '${state.error}');
///   if (state is MutationLoading)       hideKeyboard(ctx);
/// },
/// listenWhen: (prev, curr) => curr is! MutationInitial,
/// ```
///
/// ### Convenience shortcuts
///
/// [onSuccess] and [onError] are shorthand listeners scoped to those two
/// states. They coexist with [listener] — both fire when applicable.
class MutationBuilder<T> extends StatefulWidget {
  /// The mutation to observe.
  final Mutation<T> mutation;

  // ── Builder callbacks ─────────────────────────────────────────────────────

  /// Rendered while the mutation is in [MutationInitial] state.
  final Widget Function(BuildContext context) initial;

  /// Rendered while the mutation is in [MutationLoading] state.
  final Widget Function(BuildContext context) loading;

  /// Rendered when the mutation completes with data ([MutationSuccess]) and
  /// [emptyWhen] either returns false or is not provided.
  final Widget Function(BuildContext context, T data) success;

  /// Rendered when the mutation fails ([MutationError]).
  final Widget Function(BuildContext context, Object error) error;

  /// Rendered when [emptyWhen] returns true on successful data.
  /// Required when [emptyWhen] is provided.
  final Widget Function(BuildContext context)? empty;

  // ── Empty condition ───────────────────────────────────────────────────────

  /// Called on successful data to decide whether to show [empty] or [success].
  ///
  /// ```dart
  /// emptyWhen: (items) => items.isEmpty,
  /// emptyWhen: (user)  => user == null,
  /// ```
  ///
  /// When null, [empty] is never rendered — [success] always handles data.
  final bool Function(T data)? emptyWhen;

  // ── Listener + listenWhen ─────────────────────────────────────────────────

  /// Called as a side effect on every state transition (or when [listenWhen]
  /// allows it). Does not rebuild the widget.
  ///
  /// ```dart
  /// listener: (ctx, state) {
  ///   if (state is MutationLoading) hideKeyboard(ctx);
  ///   if (state is MutationSuccess<List<Post>>) trackEvent('posts_loaded');
  ///   if (state is MutationError) showSnackBar(ctx, '${state.error}');
  /// },
  /// ```
  final void Function(BuildContext context, MutationState<T> state)? listener;

  /// Return `true` to call [listener], `false` to skip.
  /// When null, [listener] is called on every state change.
  final bool Function(MutationState<T> previous, MutationState<T> current)?
      listenWhen;

  // ── Convenience side-effect shortcuts ────────────────────────────────────

  /// Shorthand fired when transitioning to [MutationSuccess].
  /// Coexists with [listener].
  final void Function(BuildContext context, T data)? onSuccess;

  /// Shorthand fired when transitioning to [MutationError].
  /// Coexists with [listener].
  final void Function(BuildContext context, Object error)? onError;

  // ── Rebuild filtering ─────────────────────────────────────────────────────

  /// Return `true` to rebuild, `false` to skip.
  /// When null, every state change triggers a rebuild.
  final bool Function(MutationState<T> previous, MutationState<T> current)?
      buildWhen;

  const MutationBuilder({
    super.key,
    required this.mutation,
    required this.initial,
    required this.loading,
    required this.success,
    required this.error,
    this.empty,
    this.emptyWhen,
    this.listener,
    this.listenWhen,
    this.onSuccess,
    this.onError,
    this.buildWhen,
  }) : assert(
          emptyWhen == null || empty != null,
          'Provide an `empty` builder when using `emptyWhen`.',
        );

  @override
  State<MutationBuilder<T>> createState() => _MutationBuilderState<T>();
}

class _MutationBuilderState<T> extends State<MutationBuilder<T>> {
  late MutationState<T> _lastState;

  @override
  void initState() {
    super.initState();
    _lastState = widget.mutation.state;
    widget.mutation.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(MutationBuilder<T> old) {
    super.didUpdateWidget(old);
    if (old.mutation != widget.mutation) {
      old.mutation.removeListener(_onChanged);
      _lastState = widget.mutation.state;
      widget.mutation.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.mutation.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final next = widget.mutation.state;
    final previous = _lastState;

    if (identical(previous, next)) return;

    // ── Side effects (post-frame to have a valid context) ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Full listener + listenWhen
      if (widget.listener != null) {
        final shouldListen =
            widget.listenWhen == null || widget.listenWhen!(previous, next);
        if (shouldListen) widget.listener!(context, next);
      }

      // Convenience shortcuts
      if (next is MutationSuccess<T> && widget.onSuccess != null) {
        widget.onSuccess!(context, next.data);
      }
      if (next is MutationError<T> && widget.onError != null) {
        widget.onError!(context, next.error);
      }
    });

    // ── Rebuild filtering ──
    if (widget.buildWhen != null && !widget.buildWhen!(previous, next)) {
      _lastState = next;
      return;
    }

    setState(() {
      _lastState = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _lastState;
    return switch (s) {
      MutationInitial<T>() => widget.initial(context),
      MutationLoading<T>() => widget.loading(context),
      MutationSuccess<T>() => _buildSuccess(context, s.data),
      MutationError<T>() => widget.error(context, s.error),
      _ => widget.initial(context),
    };
  }

  Widget _buildSuccess(BuildContext context, T data) {
    if (widget.emptyWhen != null && widget.emptyWhen!(data)) {
      return widget.empty!(context);
    }
    return widget.success(context, data);
  }
}
