import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models.dart';
import '../services/image_service.dart';
import '../theme.dart';

/// Ürün fotoğrafı; fotoğraf yoksa kategori ikonu gösterir.
/// Fotoğraf Cloudinary'den küçültülmüş ve sıkıştırılmış (WebP/AVIF) inilir,
/// telefonda da önbelleğe alınır: uygulama hafif ve hızlı kalır.
class ProductImage extends StatelessWidget {
  final Product product;
  final double iconSize;
  final int imageWidth;

  const ProductImage({
    super.key,
    required this.product,
    this.iconSize = 42,
    this.imageWidth = 500,
  });

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    if (url == null || url.isEmpty) {
      return Center(
        child: Icon(product.icon, size: iconSize, color: kPrimaryDark),
      );
    }
    return CachedNetworkImage(
      imageUrl: ImageService.optimized(url, width: imageWidth),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.image_not_supported_outlined, color: kMuted),
      ),
    );
  }
}
