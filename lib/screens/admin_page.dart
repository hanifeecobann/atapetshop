import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../models.dart';
import '../services/admin_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/status_chip.dart';
import 'admin_extras_page.dart';
import 'admin_products_page.dart';

/// Yönetim paneli. Yalnızca Firestore'da admins/{uid} belgesi olan hesaplar görür.
class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    if (!s.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Yönetim paneli')),
        body: const Center(
          child: Text('Bu sayfaya erişim yetkin yok.',
              style: TextStyle(color: kMuted)),
        ),
      );
    }

    final newCount = s.newOrderCount;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Yönetim paneli'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: kPrimaryDark,
            indicatorColor: kPrimary,
            tabs: [
              Tab(
                child: Badge(
                  isLabelVisible: newCount > 0,
                  label: Text('$newCount'),
                  offset: const Offset(10, -6),
                  child: const Text('Siparişler'),
                ),
              ),
              const Tab(text: 'Ürünler'),
              const Tab(text: 'Duyuru'),
              const Tab(text: 'Mağaza'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminOrdersTab(),
            AdminProductsTab(),
            AnnouncementTab(),
            StoreTab(),
          ],
        ),
      ),
    );
  }
}

/// Müşterilerden gelen siparişler (anlık düşer).
class AdminOrdersTab extends StatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  String? _filter; // null = tümü

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final orders = s.allOrders
        .where((o) => _filter == null || o.status == _filter)
        .toList();

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Tümü'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              for (final st in kOrderStatuses)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(st),
                    selected: _filter == st,
                    onSelected: (_) => setState(() => _filter = st),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Bu durumda sipariş yok. Yeni sipariş gelince burada görünür; '
                      'uygulama açıkken sesli uyarı verir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kMuted),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _AdminOrderCard(order: orders[i]),
                ),
        ),
      ],
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderRecord order;

  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final o = order;

    // Yeni siparişlerde iki kontrol:
    // 1) Stok yetiyor mu?  2) Tutar güncel fiyatlarla uyuşuyor mu?
    final lackStock = <String>[];
    var expected = 0.0;
    var knownAll = true;
    for (final l in o.lines) {
      final p = s.productById(l.productId);
      if (p == null) {
        knownAll = false;
        continue;
      }
      expected += p.price * l.qty;
      if (o.status == 'Yeni' && l.qty > p.stock) {
        lackStock.add('${p.name} (stokta ${p.stock})');
      }
    }
    final priceMismatch = o.status == 'Yeni' &&
        knownAll &&
        (expected - o.subtotal).abs() > 0.01;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#${o.shortId}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(formatDate(o.date),
                  style: const TextStyle(fontSize: 12, color: kMuted)),
              const Spacer(),
              StatusChip(o.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 18, color: kPrimaryDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text(o.userName,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => callPhone(o.phone),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 18, color: kPrimaryDark),
                  const SizedBox(width: 6),
                  Text(o.phone,
                      style: const TextStyle(
                          color: kPrimaryDark,
                          decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: kPrimaryDark),
              const SizedBox(width: 6),
              Expanded(
                child: Text('${o.address.title} · ${o.address.summary}',
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final l in o.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${l.qty} × ${l.name}',
                        style: const TextStyle(fontSize: 13)),
                  ),
                  Text(tl(l.price * l.qty),
                      style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          if (o.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Not: ${o.note}',
                style: const TextStyle(fontSize: 12, color: kMuted)),
          ],
          if (lackStock.isNotEmpty) ...[
            const SizedBox(height: 8),
            _Warning('Stok yetersiz: ${lackStock.join(', ')}'),
          ],
          if (priceMismatch) ...[
            const SizedBox(height: 8),
            _Warning(
                'Sipariş tutarı güncel fiyatlarla uyuşmuyor (güncel ara toplam: ${tl(expected)}). Teslimattan önce kontrol et.'),
          ],
          const Divider(height: 20),
          Row(
            children: [
              const Text('Ara toplam',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              const Spacer(),
              Text(tl(o.subtotal), style: const TextStyle(fontSize: 12)),
            ],
          ),
          Row(
            children: [
              const Text('Teslimat',
                  style: TextStyle(fontSize: 12, color: kMuted)),
              const Spacer(),
              Text(o.deliveryFee == 0 ? 'Ücretsiz' : tl(o.deliveryFee),
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tahsil edilecek: ${tl(o.total)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: kPrimaryDark)),
                  Text(o.paymentMethod,
                      style: const TextStyle(fontSize: 12, color: kMuted)),
                ],
              ),
              const Spacer(),
              DropdownButton<String>(
                value: kOrderStatuses.contains(o.status) ? o.status : null,
                hint: const Text('Durum'),
                underline: const SizedBox.shrink(),
                items: [
                  for (final st in kOrderStatuses)
                    DropdownMenuItem(value: st, child: Text(st)),
                ],
                onChanged: (v) async {
                  if (v == null || v == o.status) return;
                  try {
                    await AdminService.updateOrderStatus(o.id, v);
                  } catch (e) {
                    showMsg('Durum güncellenemedi: $e');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String text;

  const _Warning(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEE9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: kSale),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A3A24))),
          ),
        ],
      ),
    );
  }
}
