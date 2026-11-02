import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/product_card.dart';
import 'address_page.dart';
import 'auth_page.dart';
import 'categories_page.dart';

class HomePage extends StatelessWidget {
  final void Function(int) onGoTo;

  const HomePage({super.key, required this.onGoTo});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final address = s.profile.selectedAddress;
    final all = s.products;
    final popular = all.take(6).toList();
    final maxDiscount = all.fold<int>(
        0, (m, p) => p.discountPercent > m ? p.discountPercent : m);

    String addressText() {
      if (!s.loggedIn) return 'Giriş yaparak adres ekle';
      return address == null
          ? 'Teslimat adresi ekle'
          : 'Teslimat: ${address.title}';
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Teslimat adresi
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        s.loggedIn ? const AddressPage() : const AuthPage(),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: kPrimaryDark, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          addressText(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kInk, fontSize: 13),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: kMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Arama çubuğu (dokununca Kategoriler sekmesine geçer)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onGoTo(1),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: kMuted),
                      SizedBox(width: 8),
                      Text('Mama, oyuncak, marka ara',
                          style: TextStyle(color: kMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Yöneticinin yazdığı duyuru (kapatılabilir)
              if (s.visibleAnnouncement != null) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                  decoration: BoxDecoration(
                    color: kTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.campaign_outlined,
                            color: kPrimaryDark, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.visibleAnnouncement!.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, color: kInk)),
                            if (s.visibleAnnouncement!.body.isNotEmpty)
                              Text(s.visibleAnnouncement!.body,
                                  style: const TextStyle(
                                      fontSize: 13, color: kInk)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kapat',
                        visualDensity: VisualDensity.compact,
                        onPressed: s.dismissAnnouncement,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Kampanya bannerı: gerçek indirimlerden beslenir
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maxDiscount > 0 ? 'Fırsatlar' : 'Hoş geldin',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maxDiscount > 0
                                ? 'Seçili ürünlerde\n%$maxDiscount\'e varan indirim'
                                : 'Dostların için\nen iyisi burada',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: kPrimaryDark,
                              minimumSize: const Size(64, 38),
                            ),
                            onPressed: () => onGoTo(1),
                            child: const Text('Keşfet'),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.pets, size: 64, color: Color(0x66FFFFFF)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kategoriler
              Row(
                children: [
                  for (final c in kCategories)
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductListPage(
                              title: c.name,
                              filter: (p) => p.category == c.name,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: kTint,
                                child: Icon(c.icon, color: kPrimaryDark),
                              ),
                              const SizedBox(height: 6),
                              Text(c.name,
                                  style: const TextStyle(
                                      fontSize: 12, color: kInk)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Mağazaya yol tarifi
              Material(
                color: kTint,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: kPrimaryDark,
                    child: Icon(Icons.directions, color: Colors.white),
                  ),
                  title: const Text('Mağazaya yol tarifi al',
                      style:
                          TextStyle(color: kInk, fontWeight: FontWeight.w600)),
                  subtitle: Text(s.store.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openDirections(s.store.lat, s.store.lng),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Popüler ürünler',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: kInk),
              ),
              const SizedBox(height: 10),
              if (!s.productsLoaded)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (popular.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('Ürünler çok yakında burada olacak.',
                        style: TextStyle(color: kMuted)),
                  ),
                ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverGrid(
            gridDelegate: productGridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, i) => ProductCard(product: popular[i]),
              childCount: popular.length,
            ),
          ),
        ),
      ],
    );
  }
}
