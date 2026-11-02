import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/actions.dart';
import '../widgets/product_image.dart';

class ProductPage extends StatelessWidget {
  final Product product;

  const ProductPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    // Yönetici fiyat ya da stoğu değiştirirse sayfa güncel kalsın.
    final p = s.productById(product.id) ?? product;
    final isFav = s.profile.favorites.contains(p.id);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Favorilere ekle',
            onPressed: () => toggleFavoriteUi(context, p),
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? kSale : kInk,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 240,
              child: ColoredBox(
                color: kTint,
                child: ProductImage(product: p, iconSize: 84, imageWidth: 900),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(p.brand, style: const TextStyle(color: kMuted, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            p.name,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600, color: kInk),
          ),
          const SizedBox(height: 10),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 10,
            runSpacing: 6,
            children: [
              Text(
                tl(p.price),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryDark),
              ),
              if (p.onSale)
                Text(
                  tl(p.oldPrice!),
                  style: const TextStyle(
                    color: kMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              if (p.onSale)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSale,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '%${p.discountPercent} indirim',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            !p.inStock
                ? 'Şu an stokta yok'
                : p.lowStock
                    ? 'Son ${p.stock} adet kaldı'
                    : 'Stokta var',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: !p.inStock || p.lowStock ? kSale : kPrimaryDark,
            ),
          ),
          const SizedBox(height: 16),
          if (p.description.isNotEmpty)
            Text(p.description, style: const TextStyle(color: kInk, height: 1.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.category_outlined, size: 18),
                label: Text(p.category),
                backgroundColor: kTint,
                side: BorderSide.none,
              ),
              const Chip(
                avatar: Icon(Icons.payments_outlined, size: 18),
                label: Text('Kapıda ödeme'),
                backgroundColor: kTint,
                side: BorderSide.none,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: () => addToCartUi(context, p),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(p.inStock
                ? 'Sepete ekle · ${tl(p.price)}'
                : 'Şu an stokta yok'),
          ),
        ),
      ),
    );
  }
}
