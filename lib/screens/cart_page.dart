import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/product_image.dart';
import 'auth_page.dart';
import 'checkout_page.dart';
import 'orders_page.dart';

class CartPage extends StatelessWidget {
  final void Function(int) onGoTo;

  const CartPage({super.key, required this.onGoTo});

  Future<void> _checkout(BuildContext context, AppState s) async {
    if (!s.meetsMinimum) {
      showMsg('Minimum sepet tutarı ${tl(s.store.minOrder)}. '
          '${tl(s.remainingToMinimum)} daha ürün ekle.');
      return;
    }
    if (!s.loggedIn) {
      showMsg('Sipariş vermek için giriş yap ya da kayıt ol.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      return;
    }
    final ordered = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
    if (ordered == true && context.mounted) {
      showMsg('Siparişin alındı. Ödemeyi teslimatta yapacaksın.');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const OrdersPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lines = s.cartLines;

    if (lines.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 56, color: kPrimary),
              const SizedBox(height: 12),
              const Text('Sepetin boş',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Sevimli dostların için ürünlere göz at.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => onGoTo(0),
                child: const Text('Alışverişe başla'),
              ),
            ],
          ),
        ),
      );
    }

    final fee = s.deliveryFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('Sepetim',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w600, color: kInk)),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: lines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final line = lines[i];
              final p = line.product;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ColoredBox(
                          color: kTint,
                          child: ProductImage(
                              product: p, iconSize: 26, imageWidth: 200),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.brand,
                              style: const TextStyle(
                                  fontSize: 11, color: kMuted)),
                          Text(p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(tl(p.price * line.qty),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryDark)),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Azalt',
                      onPressed: () => s.changeQty(p.id, -1),
                      icon: Icon(
                        line.qty == 1
                            ? Icons.delete_outline
                            : Icons.remove_circle_outline,
                        color: kPrimaryDark,
                      ),
                    ),
                    Text('${line.qty}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Artır',
                      onPressed: () {
                        final error = s.changeQty(p.id, 1);
                        if (error != null) showMsg(error);
                      },
                      icon: const Icon(Icons.add_circle_outline,
                          color: kPrimaryDark),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: Colors.white,
          child: Column(
            children: [
              if (!s.meetsMinimum)
                _Hint(
                  icon: Icons.info_outline,
                  text:
                      'Minimum sepet tutarı ${tl(s.store.minOrder)}. ${tl(s.remainingToMinimum)} daha ürün ekle.',
                  color: kSale,
                )
              else if (s.remainingToFreeDelivery > 0)
                _Hint(
                  icon: Icons.local_shipping_outlined,
                  text:
                      '${tl(s.remainingToFreeDelivery)} daha ekle, teslimat ücretsiz olsun.',
                  color: kPrimaryDark,
                ),
              _SumRow('Ara toplam', tl(s.cartSubtotal)),
              _SumRow('Teslimat', fee == 0 ? 'Ücretsiz' : tl(fee)),
              const Divider(height: 16),
              Row(
                children: [
                  const Text('Toplam',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(tl(s.cartTotal),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryDark)),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.payments_outlined, size: 16, color: kMuted),
                  SizedBox(width: 6),
                  Text('Ödeme kapıda yapılır',
                      style: TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _checkout(context, s),
                  child: const Text('Siparişe devam et'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SumRow extends StatelessWidget {
  final String label;
  final String value;

  const _SumRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: kMuted)),
          const Spacer(),
          Text(value),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Hint({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12, color: color)),
          ),
        ],
      ),
    );
  }
}
