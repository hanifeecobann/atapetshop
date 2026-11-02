import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/status_chip.dart';

/// Müşterinin önceki alışverişleri ve canlı sipariş durumu.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Siparişlerim')),
      body: s.myOrders.isEmpty
          ? const Center(
              child: Text('İlk siparişini verdiğinde burada görünecek.',
                  style: TextStyle(color: kMuted)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: s.myOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OrderCard(order: s.myOrders[i]),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderRecord order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();

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
              Text('#${order.shortId}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(formatDate(order.date),
                  style: const TextStyle(fontSize: 12, color: kMuted)),
              const Spacer(),
              StatusChip(order.status),
            ],
          ),
          const SizedBox(height: 8),
          for (final l in order.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('${l.qty} × ${l.name}',
                  style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 6),
          Text(
            order.deliveryFee > 0
                ? 'Teslimat ücreti: ${tl(order.deliveryFee)}'
                : 'Teslimat ücretsiz',
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
          Text('Teslimat: ${order.address.title} · ${order.paymentMethod}',
              style: const TextStyle(fontSize: 12, color: kMuted)),
          const Divider(height: 20),
          Row(
            children: [
              Text(tl(order.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: kPrimaryDark)),
              const Spacer(),
              if (order.status == 'Yeni')
                TextButton(
                  onPressed: () async {
                    final error = await s.cancelOrder(order);
                    if (error != null) showMsg(error);
                  },
                  child: const Text('İptal et'),
                ),
              OutlinedButton(
                onPressed: () {
                  s.reorder(order);
                  showMsg('Ürünler sepetine eklendi');
                },
                child: const Text('Tekrar sipariş ver'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
