import 'package:flutter/widgets.dart';

import '../solid.dart';

// =============================================================================
// SOLID PROVIDER
// =============================================================================

/// Internal InheritedWidget that carries a [ChangeNotifier] down the tree.
class _SolidInherited<T extends ChangeNotifier> extends InheritedWidget {
  final T value;

  const _SolidInherited({required this.value, required super.child});

  /// Never triggers rebuilds — reactivity is handled by [ListenableBuilder]
  /// inside each observer widget.
  @override
  bool updateShouldNotify(_SolidInherited<T> old) => false;
}

/// Provides a [ChangeNotifier] (such as a [Solid]) to the
/// widget subtree.
///
/// **Create mode** – creates the instance and disposes it when removed:
/// ```dart
/// SolidProvider<LoginViewModel>(
///   create: LoginViewModel.new,
///   child: LoginPage(),
/// )
/// ```
///
/// **Value mode** – wraps an existing instance without disposing it.
/// Use when you own the instance yourself (e.g. created in `initState`):
/// ```dart
/// class _PageState extends State<Page> {
///   late final _vm = LoginViewModel();
///
///   @override
///   void dispose() { _vm.dispose(); super.dispose(); }
///
///   @override
///   Widget build(BuildContext context) => SolidProvider<LoginViewModel>.value(
///     value: _vm,
///     child: LoginPage(),
///   );
/// }
/// ```
///
/// Retrieve anywhere below with [SolidProvider.of] or `context.solid<T>()`.
class SolidProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function()? _create;
  final T? _value;
  final Widget child;

  const SolidProvider({
    super.key,
    required T Function() create,
    required this.child,
  })  : _create = create,
        _value = null;

  const SolidProvider.value({
    super.key,
    required T value,
    required this.child,
  })  : _create = null,
        _value = value;

  /// Returns a copy of this provider with [newChild] substituted as the child.
  /// Preserves the concrete generic [T] — used by [MultiSolidProvider].
  SolidProvider<T> _withChild(Widget newChild) {
    if (_value != null) {
      return SolidProvider<T>.value(value: _value, child: newChild);
    }
    return SolidProvider<T>(create: _create!, child: newChild);
  }

  @override
  State<SolidProvider<T>> createState() => _SolidProviderState<T>();

  /// Retrieves the nearest [T] from the widget tree.
  ///
  /// No [Builder] needed — call from any descendant widget's `build` method.
  static T of<T extends ChangeNotifier>(BuildContext context) {
    final inherited =
        context.getInheritedWidgetOfExactType<_SolidInherited<T>>();
    if (inherited == null) {
      throw Exception(
        'No SolidProvider<$T> found in context. '
        'Make sure SolidProvider<$T> is an ancestor of this widget.',
      );
    }
    return inherited.value;
  }
}

class _SolidProviderState<T extends ChangeNotifier>
    extends State<SolidProvider<T>> {
  late T _instance;
  late bool _owns;

  @override
  void initState() {
    super.initState();
    if (widget._value != null) {
      _instance = widget._value!;
      _owns = false;
    } else {
      _instance = widget._create!();
      _owns = true;
    }
  }

  @override
  void dispose() {
    if (_owns) _instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SolidInherited<T>(
      value: _instance,
      child: widget.child,
    );
  }
}

// =============================================================================
// MULTI SOLID PROVIDER
// =============================================================================

/// Nests multiple [SolidProvider] widgets without indentation pyramids.
///
/// ```dart
/// MultiSolidProvider(
///   providers: [
///     SolidProvider<AuthViewModel>(create: AuthViewModel.new, child: SizedBox()),
///     SolidProvider<CartViewModel>(create: CartViewModel.new, child: SizedBox()),
///   ],
///   child: MyApp(),
/// )
/// ```
class MultiSolidProvider extends StatelessWidget {
  final List<SolidProvider<ChangeNotifier>> providers;
  final Widget child;

  const MultiSolidProvider({
    super.key,
    required this.providers,
    required this.child,
  }) : assert(providers.length > 0, 'providers must not be empty');

  @override
  Widget build(BuildContext context) {
    return providers.reversed.fold<Widget>(
      child,
      (inner, provider) => provider._withChild(inner),
    );
  }
}
