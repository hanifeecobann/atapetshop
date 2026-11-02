import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data.dart';
import '../models.dart';
import '../utils.dart';

/// Uygulamanın tüm verisi:
/// - Ürünler, mağaza bilgisi, duyuru: Firestore'dan canlı gelir (herkes görür)
/// - Profil, adresler, favoriler, siparişler: giriş yapan kullanıcıya ait, Firestore'da
/// - Sepet: telefonda (yerel) saklanır
class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  SharedPreferences? _prefs;

  User? user;
  bool isAdmin = false;
  bool productsLoaded = false;

  List<Product> allProducts = const [];
  Map<String, Product> _productMap = const {};
  StoreInfo store = StoreInfo.defaults;
  Announcement? announcement;
  String? _dismissedAnnouncement;
  UserProfile profile = UserProfile.empty;
  List<OrderRecord> myOrders = const [];
  List<OrderRecord> allOrders = const []; // yalnızca yönetici için dolar
  final List<CartItem> cart = [];

  final Set<String> _knownOrderIds = {};
  bool _allOrdersReady = false;

  StreamSubscription<dynamic>? _productsSub;
  StreamSubscription<dynamic>? _storeSub;
  StreamSubscription<dynamic>? _announcementSub;
  StreamSubscription<dynamic>? _authSub;
  StreamSubscription<dynamic>? _profileSub;
  StreamSubscription<dynamic>? _adminSub;
  StreamSubscription<dynamic>? _ordersSub;
  StreamSubscription<dynamic>? _allOrdersSub;

  bool get loggedIn => user != null;

  /// Müşterilerin gördüğü (satışta olan) ürünler.
  List<Product> get products => allProducts.where((p) => p.active).toList();

  List<String> get brands {
    final list = products
        .map((p) => p.brand)
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    list.sort();
    return list;
  }

  Product? productById(String id) => _productMap[id];

  int get newOrderCount => allOrders.where((o) => o.status == 'Yeni').length;

  /// Kapatılmamış, aktif duyuru (yoksa null).
  Announcement? get visibleAnnouncement {
    final a = announcement;
    if (a == null || !a.active || a.title.isEmpty) return null;
    return a.id == _dismissedAnnouncement ? null : a;
  }

  void dismissAnnouncement() {
    final a = announcement;
    if (a == null) return;
    _dismissedAnnouncement = a.id;
    _prefs?.setString('dismissedAnn', a.id);
    notifyListeners();
  }

  // ---------- Başlatma ----------

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _dismissedAnnouncement = _prefs?.getString('dismissedAnn');
    _loadCart();

    _productsSub = _db.collection('products').snapshots().listen((snap) {
      final list = snap.docs.map(Product.fromDoc).toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      allProducts = list;
      _productMap = {for (final p in list) p.id: p};
      productsLoaded = true;
      // Henüz sunucudan veri gelmediyse (boş önbellek) sepeti silme.
      if (!(snap.metadata.isFromCache && list.isEmpty)) _pruneCart();
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('Ürünler okunamadı: $e');
      productsLoaded = true;
      notifyListeners();
    });

    _storeSub = _db.collection('settings').doc('store').snapshots().listen(
      (snap) {
        final data = snap.data();
        store = data == null ? StoreInfo.defaults : StoreInfo.fromMap(data);
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Mağaza bilgisi okunamadı: $e'),
    );

    _announcementSub =
        _db.collection('settings').doc('announcement').snapshots().listen(
      (snap) {
        final data = snap.data();
        announcement = data == null ? null : Announcement.fromMap(data);
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Duyuru okunamadı: $e'),
    );

    _authSub = _auth.authStateChanges().listen(_onAuth);
  }

  Future<void> _onAuth(User? u) async {
    await _profileSub?.cancel();
    await _adminSub?.cancel();
    await _ordersSub?.cancel();
    await _allOrdersSub?.cancel();
    _profileSub = _adminSub = _ordersSub = _allOrdersSub = null;

    user = u;
    isAdmin = false;
    profile = UserProfile.empty;
    myOrders = const [];
    allOrders = const [];
    _allOrdersReady = false;
    _knownOrderIds.clear();

    if (u == null) {
      notifyListeners();
      return;
    }

    profile = UserProfile.fromMap(const {}, fallbackEmail: u.email ?? '');

    _profileSub = _db.collection('users').doc(u.uid).snapshots().listen(
      (snap) {
        profile = UserProfile.fromMap(snap.data() ?? const {},
            fallbackEmail: u.email ?? '');
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Profil okunamadı: $e'),
    );

    _adminSub = _db.collection('admins').doc(u.uid).snapshots().listen(
      (snap) {
        final value = snap.exists;
        if (value != isAdmin) {
          isAdmin = value;
          _watchAllOrders();
        }
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Yönetici kontrolü yapılamadı: $e'),
    );

    _ordersSub = _db
        .collection('orders')
        .where('userId', isEqualTo: u.uid)
        .snapshots()
        .listen(
      (snap) {
        final list = snap.docs.map(OrderRecord.fromDoc).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        myOrders = list;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Siparişler okunamadı: $e'),
    );

    notifyListeners();
  }

  /// Yönetici için tüm siparişler. Uygulama açıkken yeni sipariş düşünce
  /// ses çalar ve ekranda uyarı gösterir (ücretsiz planda push bildirimi yok).
  void _watchAllOrders() {
    _allOrdersSub?.cancel();
    _allOrdersSub = null;
    _allOrdersReady = false;
    _knownOrderIds.clear();
    if (!isAdmin) {
      allOrders = const [];
      return;
    }
    _allOrdersSub = _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .listen(
      (snap) {
        final list = snap.docs.map(OrderRecord.fromDoc).toList();

        if (_allOrdersReady) {
          for (final change in snap.docChanges) {
            if (change.type != DocumentChangeType.added) continue;
            if (change.doc.metadata.hasPendingWrites) continue;
            final o = OrderRecord.fromDoc(change.doc);
            final fresh = DateTime.now().difference(o.date).inMinutes < 3;
            if (o.status == 'Yeni' && fresh && !_knownOrderIds.contains(o.id)) {
              SystemSound.play(SystemSoundType.alert);
              showMsg('Yeni sipariş: ${o.userName} · ${tl(o.total)}');
            }
          }
        }
        _knownOrderIds.addAll(list.map((o) => o.id));
        _allOrdersReady = true;

        allOrders = list;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('Tüm siparişler okunamadı: $e'),
    );
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _storeSub?.cancel();
    _announcementSub?.cancel();
    _authSub?.cancel();
    _profileSub?.cancel();
    _adminSub?.cancel();
    _ordersSub?.cancel();
    _allOrdersSub?.cancel();
    super.dispose();
  }

  // ---------- Hesap ----------

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'E-posta adresi geçerli görünmüyor.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta ya da şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta ile zaten bir hesap var. Giriş yapmayı dene.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'network-request-failed':
        return 'İnternet bağlantını kontrol et.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.';
      default:
        return 'Bir sorun oluştu (${e.code}). Tekrar dene.';
    }
  }

  /// Başarılıysa null, değilse hata mesajı döner.
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (_) {
      return 'Bir sorun oluştu. Tekrar dene.';
    }
  }

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'favorites': <String>[],
        'addresses': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (_) {
      return 'Bir sorun oluştu. Tekrar dene.';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e);
    } catch (_) {
      return 'Bir sorun oluştu. Tekrar dene.';
    }
  }

  Future<void> signOut() => _auth.signOut();

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final u = user;
    return u == null ? null : _db.collection('users').doc(u.uid);
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    await _userDoc?.set(
        {'name': name.trim(), 'phone': phone.trim()}, SetOptions(merge: true));
  }

  // ---------- Favoriler ----------

  /// Giriş yapılmamışsa false döner.
  Future<bool> toggleFavorite(String productId) async {
    final doc = _userDoc;
    if (doc == null) return false;
    final has = profile.favorites.contains(productId);
    await doc.set({
      'favorites': has
          ? FieldValue.arrayRemove([productId])
          : FieldValue.arrayUnion([productId]),
    }, SetOptions(merge: true));
    return true;
  }

  // ---------- Adresler ----------

  Future<void> addAddress({
    required String title,
    required String district,
    required String details,
  }) async {
    final doc = _userDoc;
    if (doc == null) return;
    final address = Address(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      district: district,
      details: details,
    );
    final list = [...profile.addresses, address];
    await doc.set({
      'addresses': list.map((a) => a.toJson()).toList(),
      if (profile.addresses.isEmpty || profile.selectedAddressId == null)
        'selectedAddressId': address.id,
    }, SetOptions(merge: true));
  }

  Future<void> removeAddress(String id) async {
    final doc = _userDoc;
    if (doc == null) return;
    final list = profile.addresses.where((a) => a.id != id).toList();
    await doc.set({
      'addresses': list.map((a) => a.toJson()).toList(),
      if (profile.selectedAddressId == id)
        'selectedAddressId': list.isEmpty ? null : list.first.id,
    }, SetOptions(merge: true));
  }

  Future<void> selectAddress(String id) async {
    await _userDoc?.set({'selectedAddressId': id}, SetOptions(merge: true));
  }

  // ---------- Sepet (telefonda) ----------

  void _loadCart() {
    final raw = _prefs?.getString('cart');
    cart.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      cart.addAll(list.map(CartItem.fromJson));
    } catch (_) {}
  }

  void _saveCart() {
    _prefs?.setString(
        'cart', jsonEncode(cart.map((e) => e.toJson()).toList()));
  }

  void _pruneCart() {
    final before = cart.length;
    cart.removeWhere((i) => !(_productMap[i.productId]?.active ?? false));
    if (cart.length != before) _saveCart();
  }

  List<CartLine> get cartLines {
    final lines = <CartLine>[];
    for (final item in cart) {
      final p = _productMap[item.productId];
      if (p != null) lines.add(CartLine(p, item.qty));
    }
    return lines;
  }

  int get cartCount => cartLines.fold(0, (sum, l) => sum + l.qty);

  double get cartSubtotal =>
      cartLines.fold(0.0, (sum, l) => sum + l.product.price * l.qty);

  /// Teslimat ücreti: sepet ücretsiz teslimat sınırına ulaştıysa 0.
  double get deliveryFee {
    final sub = cartSubtotal;
    if (sub <= 0) return 0;
    final free = store.freeDeliveryThreshold;
    if (free > 0 && sub >= free) return 0;
    return store.deliveryFee;
  }

  double get cartTotal => cartSubtotal + deliveryFee;

  bool get meetsMinimum => cartSubtotal >= store.minOrder;

  double get remainingToMinimum =>
      math.max(0, store.minOrder - cartSubtotal).toDouble();

  /// Ücretsiz teslimata kalan tutar (ücretsiz teslimat kapalıysa ya da zaten ücretsizse 0).
  double get remainingToFreeDelivery {
    final free = store.freeDeliveryThreshold;
    if (free <= 0 || store.deliveryFee <= 0) return 0;
    return math.max(0, free - cartSubtotal).toDouble();
  }

  /// Başarılıysa null, stok yetmezse uyarı mesajı döner.
  String? addToCart(String productId, {int qty = 1}) {
    final p = _productMap[productId];
    if (p == null) return 'Ürün bulunamadı.';
    final index = cart.indexWhere((i) => i.productId == productId);
    final current = index >= 0 ? cart[index].qty : 0;
    if (current + qty > p.stock) {
      return p.stock <= 0
          ? 'Bu ürün şu an stokta yok.'
          : 'Stokta en fazla ${p.stock} adet var.';
    }
    if (index >= 0) {
      cart[index].qty += qty;
    } else {
      cart.add(CartItem(productId, qty));
    }
    _saveCart();
    notifyListeners();
    return null;
  }

  String? changeQty(String productId, int delta) {
    final index = cart.indexWhere((i) => i.productId == productId);
    if (index < 0) return null;
    final p = _productMap[productId];
    if (delta > 0 && p != null && cart[index].qty + delta > p.stock) {
      return 'Stokta en fazla ${p.stock} adet var.';
    }
    cart[index].qty += delta;
    if (cart[index].qty <= 0) cart.removeAt(index);
    _saveCart();
    notifyListeners();
    return null;
  }

  // ---------- Sipariş (kapıda ödeme) ----------

  /// Siparişi Firestore'a yazar; yönetici panelinde anında görünür.
  /// Başarılıysa null, değilse hata mesajı döner.
  Future<String?> placeOrder({
    required Address address,
    required String phone,
    String note = '',
  }) async {
    final u = user;
    if (u == null) return 'Sipariş vermek için giriş yapmalısın.';
    final lines = cartLines;
    if (lines.isEmpty) return 'Sepetin boş.';
    if (!meetsMinimum) {
      return 'Minimum sepet tutarı ${tl(store.minOrder)}. '
          '${tl(remainingToMinimum)} daha ürün ekle.';
    }
    for (final l in lines) {
      if (l.qty > l.product.stock) {
        return '"${l.product.name}" için stokta en fazla ${l.product.stock} adet var.';
      }
    }

    try {
      await _db.collection('orders').add({
        'userId': u.uid,
        'userName': profile.name.isEmpty ? (u.email ?? '') : profile.name,
        'phone': phone,
        'items': lines
            .map((l) => OrderLine(
                  productId: l.product.id,
                  name: '${l.product.brand} ${l.product.name}',
                  qty: l.qty,
                  price: l.product.price,
                ).toJson())
            .toList(),
        'subtotal': cartSubtotal,
        'deliveryFee': deliveryFee,
        'total': cartTotal,
        'address': address.toJson(),
        'paymentMethod': kPaymentMethod,
        'status': 'Yeni',
        'stockDeducted': false,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (phone != profile.phone) {
        await _userDoc?.set({'phone': phone}, SetOptions(merge: true));
      }
      cart.clear();
      _saveCart();
      notifyListeners();
      return null;
    } on FirebaseException catch (e) {
      return 'Sipariş gönderilemedi (${e.code}). Tekrar dene.';
    } catch (_) {
      return 'Sipariş gönderilemedi. Tekrar dene.';
    }
  }

  /// Müşteri, sipariş henüz "Yeni" iken iptal edebilir.
  Future<String?> cancelOrder(OrderRecord order) async {
    try {
      await _db.collection('orders').doc(order.id).update({
        'status': 'İptal',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (_) {
      return 'Sipariş iptal edilemedi. Mağazayla iletişime geç.';
    }
  }

  /// Eski bir siparişteki ürünleri (stok yettiği kadar) sepete ekler.
  void reorder(OrderRecord order) {
    for (final line in order.lines) {
      final p = _productMap[line.productId];
      if (p == null || !p.active) continue;
      final index = cart.indexWhere((i) => i.productId == line.productId);
      final current = index >= 0 ? cart[index].qty : 0;
      final addable = math.min(line.qty, p.stock - current);
      if (addable <= 0) continue;
      if (index >= 0) {
        cart[index].qty += addable;
      } else {
        cart.add(CartItem(line.productId, addable));
      }
    }
    _saveCart();
    notifyListeners();
  }
}
