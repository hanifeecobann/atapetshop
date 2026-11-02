import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/admin_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';

/// Ana sayfada tüm müşterilere görünen duyuru (indirim, kampanya, tatil bilgisi...).
class AnnouncementTab extends StatefulWidget {
  const AnnouncementTab({super.key});

  @override
  State<AnnouncementTab> createState() => _AnnouncementTabState();
}

class _AnnouncementTabState extends State<AnnouncementTab> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bu alanı doldur' : null;

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AdminService.publishAnnouncement(
          _title.text.trim(), _body.text.trim());
      if (!mounted) return;
      _title.clear();
      _body.clear();
      showMsg('Duyuru yayınlandı');
    } catch (e) {
      showMsg('Yayınlanamadı: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    try {
      await AdminService.clearAnnouncement();
      showMsg('Duyuru kaldırıldı');
    } catch (e) {
      showMsg('Kaldırılamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = context.watch<AppState>().announcement;
    final live = current != null && current.active && current.title.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Yazdığın duyuru, uygulamayı açan her müşterinin ana sayfasında görünür. '
          'Yenisini yayınlayınca eskisinin yerine geçer; müşteri kapatırsa o duyuruyu bir daha görmez.',
          style: TextStyle(color: kMuted),
        ),
        const SizedBox(height: 16),
        if (live) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_outlined, color: kPrimaryDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Şu an yayında',
                          style: TextStyle(fontSize: 11, color: kMuted)),
                      Text(current.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      if (current.body.isNotEmpty) Text(current.body),
                    ],
                  ),
                ),
                TextButton(onPressed: _remove, child: const Text('Kaldır')),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                validator: _required,
                decoration: const InputDecoration(
                    labelText: 'Başlık', hintText: 'Hafta sonu indirimi'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _body,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Mesaj (isteğe bağlı)',
                    hintText: 'Tüm kedi mamalarında %15 indirim'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busy ? null : _publish,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Duyuruyu yayınla'),
        ),
      ],
    );
  }
}

/// Mağaza bilgileri: ad, telefon, konum, teslimat ücreti ve minimum sepet tutarı.
class StoreTab extends StatefulWidget {
  const StoreTab({super.key});

  @override
  State<StoreTab> createState() => _StoreTabState();
}

class _StoreTabState extends State<StoreTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _coords;
  late final TextEditingController _deliveryFee;
  late final TextEditingController _freeThreshold;
  late final TextEditingController _minOrder;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final store = context.read<AppState>().store;
    String n(double v) =>
        v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
    _name = TextEditingController(text: store.name);
    _phone = TextEditingController(text: store.phone);
    _coords = TextEditingController(text: '${store.lat}, ${store.lng}');
    _deliveryFee = TextEditingController(text: n(store.deliveryFee));
    _freeThreshold = TextEditingController(text: n(store.freeDeliveryThreshold));
    _minOrder = TextEditingController(text: n(store.minOrder));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _coords.dispose();
    _deliveryFee.dispose();
    _freeThreshold.dispose();
    _minOrder.dispose();
    super.dispose();
  }

  (double, double)? _parseCoords(String text) {
    final parts = text.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return (lat, lng);
  }

  String? _validateCoords(String? v) =>
      _parseCoords(v ?? '') == null ? 'Örnek: 39.9208, 32.8541' : null;

  String? _validateMoney(String? v) {
    final n = parseNumber(v ?? '');
    if (n == null || n < 0) return '0 ya da daha büyük bir tutar gir';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final c = _parseCoords(_coords.text)!;
    setState(() => _busy = true);
    try {
      await AdminService.saveStore(StoreInfo(
        name: _name.text.trim(),
        lat: c.$1,
        lng: c.$2,
        phone: _phone.text.trim(),
        deliveryFee: parseNumber(_deliveryFee.text)!,
        freeDeliveryThreshold: parseNumber(_freeThreshold.text)!,
        minOrder: parseNumber(_minOrder.text)!,
      ));
      showMsg('Mağaza bilgileri kaydedildi');
    } catch (e) {
      showMsg('Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Bu alanı doldur' : null,
                decoration: const InputDecoration(labelText: 'Mağaza adı'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mağaza telefonu', hintText: '0312 xxx xx xx'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coords,
                validator: _validateCoords,
                decoration: const InputDecoration(
                  labelText: 'Konum (enlem, boylam)',
                  helperText:
                      'Google Haritalar\'da mağazana basılı tut, üstte çıkan iki sayıyı kopyalayıp buraya yapıştır.',
                  helperMaxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Teslimat ve sepet kuralları',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliveryFee,
                validator: _validateMoney,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Teslimat ücreti (₺)',
                  helperText: '0 yazarsan teslimat her zaman ücretsiz olur.',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _freeThreshold,
                validator: _validateMoney,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ücretsiz teslimat sınırı (₺)',
                  helperText:
                      'Sepet bu tutara ulaşınca teslimat ücretsiz olur. 0 = sınır yok.',
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minOrder,
                validator: _validateMoney,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Minimum sepet tutarı (₺)',
                  helperText:
                      'Ürün toplamı bunun altındaysa sipariş verilemez. 0 = sınır yok.',
                  helperMaxLines: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: const Text('Kaydet'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            final c = _parseCoords(_coords.text);
            if (c == null) {
              showMsg('Önce geçerli bir konum gir.');
              return;
            }
            openDirections(c.$1, c.$2);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(64, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.directions_outlined),
          label: const Text('Konumu haritada dene'),
        ),
      ],
    );
  }
}
