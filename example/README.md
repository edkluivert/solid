# Solid Example App
This is the example application demonstrating how to efficiently use the `Solid` pattern to build reactive Flutter applications. 

## Structure
The example app comprises several different tabs, each managed by their own `Solid` subclass:
* `CounterTab` (`lib/counter_view_model.dart`): simple counter with async resetting.
* `TasksTab` (`lib/tasks_view_model.dart`): a todo-list showing a fetching state and modification via checkboxes.
* `AuthTab` (`lib/login_view_model.dart`): a simulated authentication view.
* `CartTab` (`lib/cart_view_model.dart`): an advanced cart state with multi-item modifications.

## Features show-cased
- Using `Solid` as the state management backbone (powered natively by `ChangeNotifier`).
- Reacting inside builders with `SolidBuilder<T, S>`.
- Triggering side effects (like Snackbars) with `SolidListener<T, S>`.
- Organizing UI architecture by cleanly separating concerns and avoiding huge widget tree rebuilds.
