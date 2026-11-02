import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../screens/product_page.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import 'actions.dart';
import 'product_image.dart';

const SliverGridDelegate productGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  mainAxisSpacing: 12,
  crossAxisSpacing: 12,
  childAspectRatio: 0.72,
);

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final isFav = s.profile.favorites.contains(product.id);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductPage(product: product)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColoredBox(
                          color: kTint,
                          child: ProductImage(product: product),
                        ),
                      ),
                    ),
                    if (product.onSale)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _Badge(
                          text: '%${product.discountPercent}',
                          color: kSale,
                        ),
                      ),
                    if (!product.inStock)
                      const Positioned(
                        bottom: 6,
                        left: 6,
                        child: _Badge(text: 'Stokta yok', color: kInk),
                      )
                    else if (product.lowStock)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: _Badge(
                            text: 'Son ${product.stock} adet', color: kInk),
                      ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Favorilere ekle',
                        onPressed: () => toggleFavoriteUi(context, product),
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? kSale : kPrimaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: kMuted)),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: kInk, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tl(product.price),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: kPrimaryDark),
                        ),
                        if (product.onSale)
                          Text(
                            tl(product.oldPrice!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: kMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Sepete ekle',
                    style: IconButton.styleFrom(backgroundColor: kPrimary),
                    onPressed: () => addToCartUi(context, product),
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
