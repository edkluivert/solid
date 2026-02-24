## 2.1.3

- **Changed**: `emit(S)` and `Push<S>` were merged into one function for better readability and maintainability.


## 2.1.2

- **Added**: `emit(S)` helper method on `Solid<S>` to safely update the primary state without Dart generic inference issues when pushing subclasses.
- **Added**: `onReady` and `onDispose` callbacks to `SolidProvider` and `SolidProvider.value` to facilitate firing initial events (like API calls) safely after the first frame renders.

## 2.1.1

- **Changed**: `initial` parameter in `MutationBuilder` is now optional. If omitted, the mutation is automatically triggered in `initState` and the widget falls back to displaying the `loading` builder state until the mutation resolves.

## 2.1.0

- **Added**: `Mutation<T>` — a reactive wrapper around async functions that automatically tracks `initial → loading → success / empty / error` lifecycle, with zero manual state management.
- **Added**: `mutation<T>(fn)` helper on `Solid` — throw-based, declares a mutation in one line inside a ViewModel.
- **Added**: `mutationEither<L, T>(fn)` helper on `Solid` — Either-based, compatible with `dartz` `Either<L, R>`, Left maps to error state, Right maps to success.
- **Added**: `MutationBuilder<T>` widget — renders the correct widget per mutation state with optional `onSuccess`/`onError` side-effect hooks and `buildWhen` filtering.
- **Added**: `MutationState<T>` sealed class with 5 subtypes: `MutationInitial`, `MutationLoading`, `MutationSuccess`, `MutationEmpty`, `MutationError`.
- **Updated**: Example app — new **Mutation** tab (⚡) demonstrating all mutation variants.

## 2.0.3

- **Major Redesign**: Solid is now a StateFlow/ViewModel pattern library.
- **Added**: `SolidViewModel<S>` – single-state ViewModel base class with `emit(S)`.
- **Added**: `SolidConsumer<T>` – combines `SolidBuilder` and `SolidListener` in one widget.
- **Removed**: Granular state management (`SolidState`, `Mutation`, `Solid` base class).
- **Simplified**: The widget API (`SolidProvider`, `SolidBuilder`, `SolidListener`) now supports any `ChangeNotifier`.
- **Updated**: Added `context.solid<T>()` extension for easy ViewModel lookup.

## 1.0.0

- Initial release.
- Granular state management with `SolidState<T>` and `Mutation<T>`.
- `Solid` abstract base class with auto-disposal.
- 8 widget variants for state and mutations.
