import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/library_model.dart';

/// Обёртка с постоянными вкладками: NavigationBar остаётся на экране,
/// пока содержимое вкладки меняется. Текущий индекс знает router —
/// поэтому это StatelessWidget.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell, // содержимое текущей вкладки
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch, // переключает вкладку
        destinations: [
          NavigationDestination(
            // Consumer — один «живой угол»: бейдж к повторению меняется с каждой мутацией
            icon: Consumer<LibraryModel>(
              builder: (context, library, child) => Badge(
                isLabelVisible: library.totalDue > 0,
                label: Text('${library.totalDue}'),
                child: child!,
              ),
              child: const Icon(Icons.layers_outlined),
            ),
            selectedIcon: Consumer<LibraryModel>(
              builder: (context, library, child) => Badge(
                isLabelVisible: library.totalDue > 0,
                label: Text('${library.totalDue}'),
                child: child!,
              ),
              child: const Icon(Icons.layers_rounded),
            ),
            label: 'Колоды',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Статистика',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
