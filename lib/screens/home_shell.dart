import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'account_page.dart';
import 'cart_page.dart';
import 'categories_page.dart';
import 'favorites_page.dart';
import 'home_page.dart';

/// Alt menü: Ana sayfa, Kategoriler, Favorilerim, Sepetim, Hesabım.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final favCount = s.profile.favorites.length;

    final pages = <Widget>[
      HomePage(onGoTo: _go),
      const CategoriesPage(),
      const FavoritesPage(),
      CartPage(onGoTo: _go),
      const AccountPage(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana sayfa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Kategoriler',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: favCount > 0,
              label: Text('$favCount'),
              child: const Icon(Icons.favorite_border),
            ),
            selectedIcon: const Icon(Icons.favorite),
            label: 'Favorilerim',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: s.cartCount > 0,
              label: Text('${s.cartCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: 'Sepetim',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }
}
