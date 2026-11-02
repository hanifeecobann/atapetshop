import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryInfo {
  final String name;
  final IconData icon;
  const CategoryInfo(this.name, this.icon);
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String description;
  final double price; // güncel satış fiyatı
  final double? oldPrice; // indirimdeyse eski (normal) fiyat
  final String? imageUrl;
  final bool active; // false ise müşteriler görmez
  final int stock; // stok adedi

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.description,
    required this.price,
    this.oldPrice,
    this.imageUrl,
    this.active = true,
    this.stock = 0,
  });

  bool get inStock => stock > 0;
  bool get lowStock => stock > 0 && stock <= 5;
  bool get onSale => oldPrice != null && oldPrice! > price;

  int get discountPercent =>
      onSale ? (((oldPrice! - price) / oldPrice!) * 100).round() : 0;

  IconData get icon {
    switch (category) {
      case 'Köpek':
        return Icons.pets;
      case 'Kedi':
        return Icons.cruelty_free;
      case 'Balık':
        return Icons.set_meal;
      case 'Kuş':
        return Icons.flutter_dash;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    // Eski sürümden kalan kayıtlar: "inStock" varsa ona göre stok ver.
    final legacyInStock = m['inStock'] as bool?;
    return Product(
      id: d.id,
      name: m['name'] as String? ?? '',
      brand: m['brand'] as String? ?? '',
      category: m['category'] as String? ?? '',
      description: m['description'] as String? ?? '',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (m['oldPrice'] as num?)?.toDouble(),
      imageUrl: m['imageUrl'] as String?,
      active: m['active'] as bool? ?? true,
      stock: (m['stock'] as num?)?.toInt() ?? ((legacyInStock ?? true) ? 99 : 0),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'category': category,
        'description': description,
        'price': price,
        'oldPrice': oldPrice,
        'imageUrl': imageUrl,
        'active': active,
        'stock': stock,
      };
}

class CartItem {
  final String productId;
  int qty;

  CartItem(this.productId, this.qty);

  Map<String, dynamic> toJson() => {'id': productId, 'qty': qty};

  factory CartItem.fromJson(Map<String, dynamic> j) =>
      CartItem(j['id'] as String, j['qty'] as int);
}

class CartLine {
  final Product product;
  final int qty;
  const CartLine(this.product, this.qty);
}

class Address {
  final String id;
  final String title;
  final String district;
  final String details;

  const Address({
    required this.id,
    required this.title,
    required this.district,
    required this.details,
  });

  String get summary => '$details, $district';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'district': district,
        'details': details,
      };

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        district: j['district'] as String? ?? '',
        details: j['details'] as String? ?? '',
      );
}

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final List<String> favorites;
  final List<Address> addresses;
  final String? selectedAddressId;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.favorites,
    required this.addresses,
    required this.selectedAddressId,
  });

  static const UserProfile empty = UserProfile(
    name: '',
    email: '',
    phone: '',
    favorites: [],
    addresses: [],
    selectedAddressId: null,
  );

  Address? get selectedAddress {
    for (final a in addresses) {
      if (a.id == selectedAddressId) return a;
    }
    return addresses.isEmpty ? null : addresses.first;
  }

  factory UserProfile.fromMap(Map<String, dynamic> m,
      {String fallbackEmail = ''}) {
    return UserProfile(
      name: m['name'] as String? ?? '',
      email: m['email'] as String? ?? fallbackEmail,
      phone: m['phone'] as String? ?? '',
      favorites:
          ((m['favorites'] as List?) ?? const []).whereType<String>().toList(),
      addresses: ((m['addresses'] as List?) ?? const [])
          .map((e) => Address.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      selectedAddressId: m['selectedAddressId'] as String?,
    );
  }
}

class StoreInfo {
  final String name;
  final double lat;
  final double lng;
  final String phone;
  final double deliveryFee; // teslimat ücreti (₺)
  final double freeDeliveryThreshold; // bu tutar ve üstü ücretsiz (0 = kapalı)
  final double minOrder; // minimum sepet tutarı (0 = sınır yok)

  const StoreInfo({
    required this.name,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.minOrder,
  });

  /// Yönetici "Mağaza" sekmesinden kendi bilgisini girene kadar kullanılır.
  static const StoreInfo defaults = StoreInfo(
    name: 'atapetshop',
    lat: 39.9208,
    lng: 32.8541,
    phone: '',
    deliveryFee: 0,
    freeDeliveryThreshold: 0,
    minOrder: 0,
  );

  factory StoreInfo.fromMap(Map<String, dynamic> m) => StoreInfo(
        name: m['name'] as String? ?? defaults.name,
        lat: (m['lat'] as num?)?.toDouble() ?? defaults.lat,
        lng: (m['lng'] as num?)?.toDouble() ?? defaults.lng,
        phone: m['phone'] as String? ?? '',
        deliveryFee: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
        freeDeliveryThreshold:
            (m['freeDeliveryThreshold'] as num?)?.toDouble() ?? 0,
        minOrder: (m['minOrder'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'phone': phone,
        'deliveryFee': deliveryFee,
        'freeDeliveryThreshold': freeDeliveryThreshold,
        'minOrder': minOrder,
      };
}

/// Ana sayfada gösterilen duyuru / indirim mesajı.
class Announcement {
  final String title;
  final String body;
  final bool active;
  final DateTime? createdAt;

  const Announcement({
    required this.title,
    required this.body,
    required this.active,
    required this.createdAt,
  });

  /// Her yeni duyuru farklı bir kimlik alır (kapatılan duyuru bir daha çıkmasın diye).
  String get id => '${createdAt?.millisecondsSinceEpoch ?? 0}';

  factory Announcement.fromMap(Map<String, dynamic> m) => Announcement(
        title: m['title'] as String? ?? '',
        body: m['body'] as String? ?? '',
        active: m['active'] as bool? ?? false,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
      );
}

class OrderLine {
  final String productId;
  final String name;
  final int qty;
  final double price;

  const OrderLine({
    required this.productId,
    required this.name,
    required this.qty,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'qty': qty,
        'price': price,
      };

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        productId: j['productId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        price: (j['price'] as num?)?.toDouble() ?? 0,
      );
}

class OrderRecord {
  final String id;
  final String userId;
  final String userName;
  final String phone;
  final String status;
  final String note;
  final String paymentMethod;
  final List<OrderLine> lines;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final Address address;
  final DateTime date;

  const OrderRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.phone,
    required this.status,
    required this.note,
    required this.paymentMethod,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.address,
    required this.date,
  });

  String get shortId =>
      id.length <= 6 ? id.toUpperCase() : id.substring(0, 6).toUpperCase();

  factory OrderRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final total = (m['total'] as num?)?.toDouble() ?? 0;
    return OrderRecord(
      id: d.id,
      userId: m['userId'] as String? ?? '',
      userName: m['userName'] as String? ?? '',
      phone: m['phone'] as String? ?? '',
      status: m['status'] as String? ?? 'Yeni',
      note: m['note'] as String? ?? '',
      paymentMethod: m['paymentMethod'] as String? ?? 'Kapıda ödeme',
      lines: ((m['items'] as List?) ?? const [])
          .map((e) => OrderLine.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      subtotal: (m['subtotal'] as num?)?.toDouble() ?? total,
      deliveryFee: (m['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: total,
      address: Address.fromJson(
          Map<String, dynamic>.from((m['address'] as Map?) ?? const {})),
      date: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
