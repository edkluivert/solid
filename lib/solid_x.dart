/// Solid — a reactive state management library for Flutter.
///
/// Powered by Flutter's native `ChangeNotifier`.
///
/// ## Core class
/// - [Solid] – extend this, define a state class, update via [push] or [update].
///
/// ## Widgets
/// | Widget | Equivalent | Purpose |
/// |---|---|---|
/// | [SolidProvider] | BlocProvider | Provide a ViewModel to the subtree |
/// | [SolidBuilder] | BlocBuilder | Rebuild UI on state change |
/// | [SolidListener] | BlocListener | Side effects (snackbars, navigation) |
/// | [SolidConsumer] | BlocConsumer | Builder + listener in one widget |
/// | [SolidSelector] | BlocSelector | Rebuild only when a slice of state changes |
///
/// ## Quick start
/// ```dart
/// class CounterViewModel extends Solid<CounterState> {
///   CounterViewModel() : super(const CounterState());
///
///   void increment() => update((s) => s.copyWith(count: s.count + 1));
/// }
///
/// SolidProvider<CounterViewModel>(
///   create: CounterViewModel.new,
///   child: SolidBuilder<CounterViewModel, CounterState>(
///     builder: (context, state) => Text('${state.count}'),
///   ),
/// )
/// ```
library solid_x;

export 'src/solid.dart';
export 'src/solid_observer.dart';
export 'src/solid_status.dart';
export 'src/widgets/solid_provider.dart';
export 'src/widgets/solid_context_extension.dart';
export 'src/widgets/solid_builder.dart';
export 'src/widgets/solid_listener.dart';
export 'src/widgets/solid_consumer.dart';
export 'src/widgets/solid_selector.dart';
