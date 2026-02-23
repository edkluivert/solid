import 'package:flutter/material.dart';
import 'package:solid_x/solid_x.dart';

import '../mutation_view_model.dart';
import '../user.dart';

class MutationTab extends StatelessWidget {
  const MutationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidProvider<MutationViewModel>(
      create: MutationViewModel.new,
      child: Scaffold(
        appBar: AppBar(title: const Text('Mutation'), centerTitle: true),
        body: const _MutationBody(),
      ),
    );
  }
}

class _MutationBody extends StatelessWidget {
  const _MutationBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.solid<MutationViewModel>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Card 1: listener + listenWhen ──────────────────────────────────
        _SectionLabel(
          color: Theme.of(context).colorScheme.primary,
          tag: 'mutation<User>',
          description: 'listener + listenWhen — react to ANY state transition',
        ),
        const SizedBox(height: 8),
        _FetchUserCard(vm: vm),

        const SizedBox(height: 24),

        // ── Card 2: emptyWhen ───────────────────────────────────────────────
        _SectionLabel(
          color: Theme.of(context).colorScheme.secondary,
          tag: 'mutation<List<User>>',
          description:
              'emptyWhen — you define what "empty" means on the success data',
        ),
        const SizedBox(height: 8),
        _FetchTeamCard(vm: vm),

        const SizedBox(height: 24),

        // ── Card 3: void mutation ───────────────────────────────────────────
        _SectionLabel(
          color: Theme.of(context).colorScheme.tertiary,
          tag: 'mutation<void>',
          description: 'No return value — onSuccess fires, data is ignored',
        ),
        const SizedBox(height: 8),
        _DeleteUserCard(vm: vm),

        const SizedBox(height: 24),

        // ── Card 4: Either-based ────────────────────────────────────────────
        _SectionLabel(
          color: Theme.of(context).colorScheme.error,
          tag: 'mutationEither<String, User>',
          description: 'Either-based — Left = typed error, Right = success',
        ),
        const SizedBox(height: 8),
        _LoginEitherCard(vm: vm, succeed: true),
        const SizedBox(height: 8),
        _LoginEitherCard(vm: vm, succeed: false),

        // ── Card 5: Auto-trigger ────────────────────────────────────────────
        _SectionLabel(
          color: Colors.teal,
          tag: 'mutation<int> (no initial)',
          description: 'Auto-triggers on first build if initial is omitted',
        ),
        const SizedBox(height: 8),
        _AutoTriggerCard(vm: vm),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card 1 — listener + listenWhen
// ---------------------------------------------------------------------------

class _FetchUserCard extends StatelessWidget {
  final MutationViewModel vm;
  const _FetchUserCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return _Card(
      borderColor: color,
      child: MutationBuilder<User>(
        mutation: vm.fetchUser,

        // Fires on every state change except initial
        listenWhen: (prev, curr) => curr is! MutationInitial,
        listener: (ctx, state) {
          final msg = switch (state) {
            MutationLoading() => 'Fetching user…',
            MutationSuccess() => 'User loaded',
            MutationError() => 'Error: ${(state as MutationError).error}',
            _ => null,
          };
          if (msg != null) _snack(ctx, msg);
        },
        initial: (ctx) => _TriggerButton(
          label: 'Fetch User',
          icon: Icons.person_search_outlined,
          color: color,
          onTap: vm.fetchUser.call,
        ),
        loading: (ctx) => const _Spinner(label: 'Fetching user…'),
        success: (ctx, user) =>
            _UserTile(user: user, color: color, onReset: vm.fetchUser.reset),
        error: (ctx, e) =>
            _ErrorTile(message: '$e', color: color, onRetry: vm.fetchUser.call),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 2 — emptyWhen
// ---------------------------------------------------------------------------

class _FetchTeamCard extends StatelessWidget {
  final MutationViewModel vm;
  const _FetchTeamCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.secondary;
    return _Card(
      borderColor: color,
      child: MutationBuilder(
        mutation: vm.fetchTeam,

        // list.isEmpty triggers the empty builder
        emptyWhen: (team) => team.isEmpty,
        listener: (ctx, state) {
          if (state is MutationSuccess<List<User>>) {
            if (state.data.length == 2) {
              print('okayyyyyy');
            }
          }
        },
        initial: (ctx) => _TriggerButton(
          label: 'Fetch Team',
          icon: Icons.group_outlined,
          color: color,
          onTap: vm.fetchTeam.call,
        ),
        loading: (ctx) => const _Spinner(label: 'Fetching team…'),
        success: (ctx, team) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${team.length} members',
              style: Theme.of(
                ctx,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            ...team.map(
              (u) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _UserTile(user: u, color: color, onReset: null),
              ),
            ),
            TextButton(
              onPressed: vm.fetchTeam.reset,
              child: const Text('Reset'),
            ),
          ],
        ),
        // Fires because emptyWhen returned true
        empty: (ctx) => Column(
          children: [
            Row(
              children: [
                Icon(Icons.inbox_outlined, color: color),
                const SizedBox(width: 8),
                const Text('No team members found'),
              ],
            ),
            TextButton(
              onPressed: vm.fetchTeam.reset,
              child: const Text('Reset'),
            ),
          ],
        ),
        error: (ctx, e) =>
            _ErrorTile(message: '$e', color: color, onRetry: vm.fetchTeam.call),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 3 — void mutation
// ---------------------------------------------------------------------------

class _DeleteUserCard extends StatelessWidget {
  final MutationViewModel vm;
  const _DeleteUserCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.tertiary;
    return _Card(
      borderColor: color,
      child: MutationBuilder<void>(
        mutation: vm.deleteUser,
        onSuccess: (ctx, _) => _snack(ctx, 'User deleted!'),
        onError: (ctx, e) => _snack(ctx, 'Error: $e', isError: true),
        initial: (ctx) => _TriggerButton(
          label: 'Delete User',
          icon: Icons.delete_outline,
          color: color,
          onTap: vm.deleteUser.call,
        ),
        loading: (ctx) => const _Spinner(label: 'Deleting…'),
        success: (ctx, _) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: color),
                const SizedBox(width: 8),
                const Text('Deleted successfully'),
              ],
            ),
            TextButton(
              onPressed: vm.deleteUser.reset,
              child: const Text('Reset'),
            ),
          ],
        ),
        error: (ctx, e) => _ErrorTile(
          message: '$e',
          color: color,
          onRetry: vm.deleteUser.call,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card 4 — mutationEither
// ---------------------------------------------------------------------------

class _LoginEitherCard extends StatelessWidget {
  final MutationViewModel vm;
  final bool succeed;
  const _LoginEitherCard({required this.vm, required this.succeed});

  @override
  Widget build(BuildContext context) {
    final color = succeed
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.error;
    final mut = succeed ? vm.loginEither : vm.loginEitherFail;

    return _Card(
      borderColor: color,
      child: MutationBuilder<User>(
        mutation: mut,
        onError: (ctx, e) => _snack(ctx, 'Left: $e', isError: true),
        initial: (ctx) => _TriggerButton(
          label: succeed ? 'Login (correct creds)' : 'Login (wrong creds)',
          icon: Icons.login_outlined,
          color: color,
          onTap: mut.call,
        ),
        loading: (ctx) => const _Spinner(label: 'Logging in…'),
        success: (ctx, user) =>
            _UserTile(user: user, color: color, onReset: mut.reset),
        error: (ctx, e) =>
            _ErrorTile(message: 'Left: $e', color: color, onRetry: mut.call),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final Color color;
  final String tag;
  final String description;

  const _SectionLabel({
    required this.color,
    required this.tag,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  const _Card({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: child,
    );
  }
}

class _TriggerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TriggerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  final String label;
  const _Spinner({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;
  final Color color;
  final VoidCallback? onReset;
  const _UserTile({required this.user, required this.color, this.onReset});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: Text(
                user.name[0].toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.check_circle_outline, color: color, size: 18),
          ],
        ),
        if (onReset != null)
          TextButton(onPressed: onReset, child: const Text('Reset')),
      ],
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final Color color;
  final VoidCallback onRetry;
  const _ErrorTile({
    required this.message,
    required this.color,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error_outline, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card 5 — Auto-trigger
// ---------------------------------------------------------------------------

class _AutoTriggerCard extends StatelessWidget {
  final MutationViewModel vm;
  const _AutoTriggerCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    return _Card(
      borderColor: Colors.teal,
      child: MutationBuilder<int>(
        mutation: vm.fetchUsersCount,
        // No initial builder! It will auto-trigger and show loading.
        loading: (ctx) => const _Spinner(label: 'Auto-loading data…'),
        success: (ctx, count) => Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.teal),
                const SizedBox(width: 8),
                Text('Total users: $count'),
              ],
            ),
            TextButton(
              onPressed: vm.fetchUsersCount.call,
              child: const Text('Reload'),
            ),
          ],
        ),
        error: (ctx, e) => _ErrorTile(
          message: '$e',
          color: Colors.teal,
          onRetry: vm.fetchUsersCount.call,
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String msg, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
}
