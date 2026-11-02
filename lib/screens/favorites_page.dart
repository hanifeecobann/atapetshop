import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';
import 'auth_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items =
        s.products.where((p) => s.profile.favorites.contains(p.id)).toList();

    Widget body;
    if (!s.loggedIn) {
      body = _Empty(
        icon: Icons.favorite_border,
        title: 'Favorilerin için giriş yap',
        text: 'Beğendiğin ürünler hesabına kaydedilir, her cihazda seni bekler.',
        button: FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AuthPage()),
          ),
          child: const Text('Giriş yap'),
        ),
      );
    } else if (items.isEmpty) {
      body = const _Empty(
        icon: Icons.favorite_border,
        title: 'Favori listen boş',
        text: 'Beğendiğin ürünlerin kalp simgesine dokun, burada toplansın.',
      );
    } else {
      body = GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: productGridDelegate,
        itemCount: items.length,
        itemBuilder: (context, i) => ProductCard(product: items[i]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Favorilerim',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, color: kInk)),
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Widget? button;

  const _Empty({
    required this.icon,
    required this.title,
    required this.text,
    this.button,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: kPrimary),
            const SizedBox(height: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted)),
            if (button != null) ...[const SizedBox(height: 16), button!],
          ],
        ),
      ),
    );
  }
}
