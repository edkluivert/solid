import 'package:example/ui/auth_tab.dart';
import 'package:example/ui/cart_tab.dart';
import 'package:example/ui/counter_tab.dart';
import 'package:example/ui/form_tab.dart';
import 'package:example/ui/mutation_tab.dart';
import 'package:example/ui/tasks_tab.dart';
import 'package:flutter/material.dart';
import 'package:solid_x/solid_x.dart';

import 'login_view_model.dart';

void main() {
  runApp(const SolidExampleApp());
}

class SolidExampleApp extends StatelessWidget {
  const SolidExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidProvider(
      create: LoginViewModel.new,
      child: MaterialApp(
        title: 'Solid Example',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5C6BC0),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),

        home: SolidBuilder<LoginViewModel, LoginState>(
          // Only rebuild when user changes (login/logout),
          // not on loading or error changes.
          buildWhen: (prev, curr) => prev.user != curr.user,
          builder: (context, state) {
            if (state.user != null) {
              return const _HomeShell();
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          CounterTab(),
          TasksTab(),
          ProfileTab(),
          CartTab(),
          MutationTab(),
          FormTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Counter',
          ),
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            label: 'Mutation',
          ),
          NavigationDestination(
            icon: Icon(Icons.dynamic_form_outlined),
            label: 'Form',
          ),
        ],
      ),
    );
  }
}
