import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../models.dart';
import '../services/admin_service.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/product_image.dart';

/// Ürün listesi: ekle, düzenle, sil, toplu indirim.
class AdminProductsTab extends StatelessWidget {
  const AdminProductsTab({super.key});

  void _edit(BuildContext context, Product? p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductEditPage(product: p)),
    );
  }

  Future<void> _delete(BuildContext context, Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürün silinsin mi?'),
        content: Text('"${p.name}" kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.deleteProduct(p);
      showMsg('Ürün silindi');
    } catch (e) {
      showMsg('Silinemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final items = s.allProducts;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _edit(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Ürün ekle'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: items.isEmpty
                      ? () => showMsg('Önce ürün ekle.')
                      : () => showDialog<void>(
                            context: context,
                            builder: (_) => _BulkDiscountDialog(products: items),
                          ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.percent),
                  label: const Text('Toplu indirim'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 56, color: kPrimary),
                        const SizedBox(height: 12),
                        const Text('Henüz ürün eklenmedi',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text(
                          'İlk ürününü ekle ya da denemek için örnek ürünleri yükle.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: kMuted),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () async {
                            try {
                              await AdminService.seedSamples();
                              showMsg('Örnek ürünler yüklendi');
                            } catch (e) {
                              showMsg('Yüklenemedi: $e');
                            }
                          },
                          child: const Text('Örnek ürünleri yükle'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final p = items[i];
                    final flags = [
                      if (!p.active) 'Gizli',
                      if (!p.inStock) 'Stokta yok' else if (p.lowStock) 'Stok azalıyor',
                    ].join(' · ');
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: SizedBox(
                          width: 52,
                          height: 52,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ColoredBox(
                              color: kTint,
                              child: ProductImage(
                                  product: p, iconSize: 24, imageWidth: 150),
                            ),
                          ),
                        ),
                        title: Text(p.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${p.brand} · ${p.category}\n'
                          '${tl(p.price)}'
                          '${p.onSale ? '  (normal ${tl(p.oldPrice!)})' : ''}'
                          ' · Stok: ${p.stock}'
                          '${flags.isEmpty ? '' : '\n$flags'}',
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _edit(context, p);
                            if (v == 'delete') _delete(context, p);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                            PopupMenuItem(value: 'delete', child: Text('Sil')),
                          ],
                        ),
                        onTap: () => _edit(context, p),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Ürün ekleme / düzenleme: bilgiler, fotoğraf, fiyat, indirim ve stok adedi.
class ProductEditPage extends StatefulWidget {
  final Product? product;

  const ProductEditPage({super.key, this.product});

  @override
  State<ProductEditPage> createState() => _ProductEditPageState();
}

class _ProductEditPageState extends State<ProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _price; // normal fiyat
  late final TextEditingController _salePrice; // indirimli fiyat (isteğe bağlı)
  late final TextEditingController _stock;
  late String _category;
  late bool _active;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  Product? get _p => widget.product;

  @override
  void initState() {
    super.initState();
    final p = _p;
    _name = TextEditingController(text: p?.name ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    // Üründe indirim varsa: normal fiyat = oldPrice, indirimli fiyat = price.
    final normal = p == null ? null : (p.oldPrice ?? p.price);
    _price = TextEditingController(text: normal == null ? '' : _fmt(normal));
    _salePrice = TextEditingController(
        text: (p != null && p.onSale) ? _fmt(p.price) : '');
    _stock = TextEditingController(text: '${p?.stock ?? 10}');
    _category = p?.category.isNotEmpty == true &&
            kCategories.any((c) => c.name == p!.category)
        ? p!.category
        : kCategories.first.name;
    _active = p?.active ?? true;
  }

  String _fmt(double v) =>
      (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _description.dispose();
    _price.dispose();
    _salePrice.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = x.name;
      });
    } catch (e) {
      showMsg('Fotoğraf seçilemedi: $e');
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bu alanı doldur' : null;

  String? _validatePrice(String? v) {
    final n = parseNumber(v ?? '');
    if (n == null || n <= 0) return 'Geçerli bir fiyat gir';
    return null;
  }

  String? _validateSale(String? v) {
    if (v == null || v.trim().isEmpty) return null; // isteğe bağlı
    final sale = parseNumber(v);
    final normal = parseNumber(_price.text);
    if (sale == null || sale <= 0) return 'Geçerli bir fiyat gir';
    if (normal != null && sale >= normal) {
      return 'İndirimli fiyat normal fiyattan düşük olmalı';
    }
    return null;
  }

  String? _validateStock(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n < 0) return '0 ya da daha büyük bir sayı gir';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final normal = parseNumber(_price.text)!;
    final sale =
        _salePrice.text.trim().isEmpty ? null : parseNumber(_salePrice.text);

    final product = Product(
      id: _p?.id ?? '',
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category,
      description: _description.text.trim(),
      price: sale ?? normal,
      oldPrice: sale == null ? null : normal,
      imageUrl: _p?.imageUrl,
      active: _active,
      stock: int.parse(_stock.text.trim()),
    );

    setState(() => _saving = true);
    try {
      await AdminService.saveProduct(
        product,
        imageBytes: _imageBytes,
        imageName: _imageName,
      );
      if (!mounted) return;
      showMsg('Ürün kaydedildi');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMsg('Kaydedilemedi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingUrl = _p?.imageUrl;

    Widget preview;
    if (_imageBytes != null) {
      preview = Image.memory(_imageBytes!, fit: BoxFit.cover);
    } else if (_p != null && existingUrl != null && existingUrl.isNotEmpty) {
      preview = ProductImage(product: _p!, imageWidth: 800);
    } else {
      preview = const Center(
        child: Icon(Icons.add_a_photo_outlined, size: 40, color: kPrimaryDark),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_p == null ? 'Ürün ekle' : 'Ürünü düzenle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pick,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ColoredBox(color: kTint, child: preview),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_imageBytes == null && existingUrl == null
                  ? 'Fotoğraf seç'
                  : 'Fotoğrafı değiştir'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              validator: _required,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Ürün adı', hintText: 'Yetişkin Köpek Maması 3 kg'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _brand,
              validator: _required,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Marka', hintText: 'Royal Canin'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in kCategories)
                  DropdownMenuItem(value: c.name, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    validator: _validatePrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Normal fiyat (₺)', hintText: '749'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _salePrice,
                    validator: _validateSale,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'İndirimli fiyat (₺)',
                        hintText: 'boş = indirim yok'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stock,
              validator: _validateStock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stok adedi',
                helperText:
                    'Sipariş "Hazırlanıyor" olunca otomatik düşer, iptalde geri eklenir. 0 olursa "Stokta yok" görünür.',
                helperMaxLines: 3,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Ürünün içeriği, kimler için uygun olduğu'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Satışta'),
              subtitle: const Text('Kapalıysa müşteriler bu ürünü görmez'),
              value: _active,
              activeColor: kPrimary,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçili kategoriye (ya da tüm ürünlere) yüzdeyle indirim uygular / kaldırır.
class _BulkDiscountDialog extends StatefulWidget {
  final List<Product> products;

  const _BulkDiscountDialog({required this.products});

  @override
  State<_BulkDiscountDialog> createState() => _BulkDiscountDialogState();
}

class _BulkDiscountDialogState extends State<_BulkDiscountDialog> {
  final _percent = TextEditingController(text: '10');
  String? _category; // null = tüm ürünler
  bool _announce = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _percent.dispose();
    super.dispose();
  }

  List<Product> get _targets => widget.products
      .where((p) => _category == null || p.category == _category)
      .toList();

  Future<void> _apply() async {
    final pct = int.tryParse(_percent.text.trim());
    if (pct == null || pct < 1 || pct > 90) {
      setState(() => _error = '1 ile 90 arasında bir yüzde gir');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final n = await AdminService.applyDiscount(_targets, pct);
      if (_announce) {
        final where =
            _category == null ? 'tüm ürünlerde' : '$_category ürünlerinde';
        await AdminService.publishAnnouncement(
            'İndirim başladı', '$where %$pct indirim seni bekliyor.');
      }
      if (!mounted) return;
      Navigator.pop(context);
      showMsg('$n ürüne %$pct indirim uygulandı');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Uygulanamadı: $e';
      });
    }
  }

  Future<void> _clear() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final n = await AdminService.clearDiscount(_targets);
      if (!mounted) return;
      Navigator.pop(context);
      showMsg('$n üründeki indirim kaldırıldı');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Kaldırılamadı: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Toplu indirim'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String?>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Hangi ürünler?'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Tüm ürünler')),
                for (final c in kCategories)
                  DropdownMenuItem<String?>(value: c.name, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _percent,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'İndirim yüzdesi', suffixText: '%'),
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _announce,
              activeColor: kPrimary,
              title: const Text('Ana sayfada duyuru yayınla'),
              onChanged: (v) => setState(() => _announce = v ?? true),
            ),
            Text('${_targets.length} ürün etkilenecek.',
                style: const TextStyle(fontSize: 12, color: kMuted)),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _busy ? null : _clear,
          child: const Text('İndirimi kaldır'),
        ),
        FilledButton(
          onPressed: _busy ? null : _apply,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Uygula'),
        ),
      ],
    );
  }
}
