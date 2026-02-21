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
