import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../data.dart';
import '../models.dart';
import 'image_service.dart';

/// Yalnızca yönetici hesabının yapabildiği işlemler.
/// (Yetki kontrolü asıl olarak firestore.rules dosyasında yapılır.)
class AdminService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Ürünler ----------

  /// [p.id] boşsa yeni ürün oluşturur, doluysa günceller.
  static Future<void> saveProduct(
    Product p, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final isNew = p.id.isEmpty;
    final doc = isNew
        ? _db.collection('products').doc()
        : _db.collection('products').doc(p.id);

    final data = p.toMap();
    if (imageBytes != null) {
      data['imageUrl'] = await ImageService.upload(imageBytes, imageName ?? '');
    }
    if (isNew) data['createdAt'] = FieldValue.serverTimestamp();
    await doc.set(data, SetOptions(merge: true));
  }

  static Future<void> deleteProduct(Product p) {
    return _db.collection('products').doc(p.id).delete();
  }

  static Future<void> seedSamples() async {
    final batch = _db.batch();
    for (final m in kSampleProducts) {
      final doc = _db.collection('products').doc();
      batch.set(doc, {
        ...m,
        'oldPrice': m['oldPrice'],
        'imageUrl': null,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // ---------- İndirimler ----------

  static Future<int> applyDiscount(List<Product> products, int percent) async {
    var count = 0;
    for (var i = 0; i < products.length; i += 400) {
      final batch = _db.batch();
      for (final p in products.skip(i).take(400)) {
        final base = p.oldPrice ?? p.price; // indirim üst üste binmesin
        final newPrice = (base * (100 - percent) / 100).roundToDouble();
        batch.update(_db.collection('products').doc(p.id),
            {'oldPrice': base, 'price': newPrice});
        count++;
      }
      await batch.commit();
    }
    return count;
  }

  static Future<int> clearDiscount(List<Product> products) async {
    final onSale = products.where((p) => p.oldPrice != null).toList();
    var count = 0;
    for (var i = 0; i < onSale.length; i += 400) {
      final batch = _db.batch();
      for (final p in onSale.skip(i).take(400)) {
        batch.update(_db.collection('products').doc(p.id),
            {'price': p.oldPrice, 'oldPrice': FieldValue.delete()});
        count++;
      }
      await batch.commit();
    }
    return count;
  }

  // ---------- Siparişler ----------

  /// Sipariş durumunu değiştirir ve stoğu otomatik yönetir:
  /// - "Yeni" ve "İptal" dışındaki bir duruma geçince ürün stokları siparişteki adet kadar düşer.
  /// - "İptal" ya da "Yeni"ye dönünce düşen stok geri eklenir.
  /// Hepsi tek işlemde (transaction) yapılır, yarım kalmaz.
  static Future<void> updateOrderStatus(String orderId, String status) async {
    final orderRef = _db.collection('orders').doc(orderId);

    await _db.runTransaction((tx) async {
      final orderSnap = await tx.get(orderRef);
      final data = orderSnap.data();
      if (data == null) return;

      final wasDeducted = data['stockDeducted'] == true;
      final shouldDeduct = status != 'Yeni' && status != 'İptal';

      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (shouldDeduct != wasDeducted) {
        final items = ((data['items'] as List?) ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final refs = items
            .map((it) => _db.collection('products').doc(it['productId'] as String))
            .toList();

        // Firestore transaction kuralı: önce tüm okumalar, sonra yazmalar.
        final snaps = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final ref in refs) {
          snaps.add(await tx.get(ref));
        }

        for (var i = 0; i < items.length; i++) {
          final productData = snaps[i].data();
          if (productData == null || productData['stock'] == null) continue;
          final qty = (items[i]['qty'] as num).toInt();
          final current = (productData['stock'] as num).toInt();
          final next = shouldDeduct
              ? (current - qty < 0 ? 0 : current - qty)
              : current + qty;
          tx.update(refs[i], {'stock': next});
        }
        updates['stockDeducted'] = shouldDeduct;
      }

      tx.update(orderRef, updates);
    });
  }

  // ---------- Duyuru ve mağaza ----------

  /// Ana sayfada tüm müşterilere görünen duyuru. Yenisini yazınca eskisinin yerine geçer.
  static Future<void> publishAnnouncement(String title, String body) {
    return _db.collection('settings').doc('announcement').set({
      'title': title,
      'body': body,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> clearAnnouncement() {
    return _db
        .collection('settings')
        .doc('announcement')
        .set({'active': false}, SetOptions(merge: true));
  }

  static Future<void> saveStore(StoreInfo info) {
    return _db.collection('settings').doc('store').set(info.toMap());
  }
}
