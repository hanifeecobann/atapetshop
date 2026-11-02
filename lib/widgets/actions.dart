import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../screens/auth_page.dart';
import '../state/app_state.dart';
import '../utils.dart';

/// Giriş yapılmamışsa giriş sayfasına yönlendirir.
Future<void> toggleFavoriteUi(BuildContext context, Product p) async {
  final s = context.read<AppState>();
  if (!s.loggedIn) {
    showMsg('Favorilere eklemek için giriş yap.');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
    return;
  }
  await s.toggleFavorite(p.id);
}

/// Stok yetmezse uyarı verir, yetiyorsa sepete ekler.
void addToCartUi(BuildContext context, Product p) {
  final error = context.read<AppState>().addToCart(p.id);
  showMsg(error ?? 'Sepete eklendi');
}
