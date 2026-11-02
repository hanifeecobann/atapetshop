import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import 'address_page.dart';

/// Sipariş özeti + teslimat bilgisi. Ödeme kapıda yapılır.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final TextEditingController _phone;
  final _note = TextEditingController();
  String? _phoneError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: context.read<AppState>().profile.phone);
  }

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<AppState>();
    final address = s.profile.selectedAddress;
    if (address == null) {
      showMsg('Önce bir teslimat adresi ekle.');
      return;
    }
    final phone = _phone.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      setState(() =>
          _phoneError = 'Kurye sana ulaşabilsin diye geçerli bir numara gir');
      return;
    }
    setState(() {
      _phoneError = null;
      _busy = true;
    });
    final error = await s.placeOrder(
      address: address,
      phone: phone,
      note: _note.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      showMsg(error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final lines = s.cartLines;
    final address = s.profile.selectedAddress;
    final fee = s.deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Siparişi tamamla')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            title: 'Ürünler',
            child: Column(
              children: [
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${l.qty} × ${l.product.name}',
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Text(tl(l.product.price * l.qty)),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Text('Ara toplam',
                        style: TextStyle(color: kMuted)),
                    const Spacer(),
                    Text(tl(s.cartSubtotal)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Teslimat ücreti',
                        style: TextStyle(color: kMuted)),
                    const Spacer(),
                    Text(fee == 0 ? 'Ücretsiz' : tl(fee)),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Text('Kapıda ödenecek',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(tl(s.cartTotal),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kPrimaryDark,
                            fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'Teslimat adresi',
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddressPage()),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, color: kPrimaryDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address == null
                          ? 'Adres ekle'
                          : '${address.title} · ${address.summary}',
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: kMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            title: 'İletişim',
            child: Column(
              children: [
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telefon numarası',
                    hintText: '05xx xxx xx xx',
                    errorText: _phoneError,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Sipariş notu (isteğe bağlı)',
                    hintText: 'Kapıda zil çalışmıyor, lütfen ara',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _Card(
            title: 'Ödeme',
            child: Row(
              children: [
                Icon(Icons.payments_outlined, color: kPrimaryDark),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$kPaymentMethod: siparişin sana ulaştığında ödersin. Şimdi kart bilgisi girmene gerek yok.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('Siparişi onayla · ${tl(s.cartTotal)}'),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kMuted)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
