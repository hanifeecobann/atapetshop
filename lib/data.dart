import 'package:flutter/material.dart';

import 'models.dart';

const List<CategoryInfo> kCategories = [
  CategoryInfo('Köpek', Icons.pets),
  CategoryInfo('Kedi', Icons.cruelty_free),
  CategoryInfo('Balık', Icons.set_meal),
  CategoryInfo('Kuş', Icons.flutter_dash),
];

const String kPaymentMethod = 'Kapıda ödeme';

/// Sipariş durumları (yönetici bu sırayla ilerletir).
/// "Yeni" ve "İptal" dışındaki durumlara geçince stok düşer; iptalde geri eklenir.
const List<String> kOrderStatuses = [
  'Yeni',
  'Hazırlanıyor',
  'Yolda',
  'Teslim edildi',
  'İptal',
];

/// Yönetim panelindeki "Örnek ürünleri yükle" düğmesi bu listeyi kullanır.
const List<Map<String, dynamic>> kSampleProducts = [
  {
    'name': 'Yetişkin Köpek Maması 3 kg',
    'brand': 'Royal Canin',
    'category': 'Köpek',
    'price': 749.0,
    'oldPrice': 879.0,
    'stock': 20,
    'description': 'Orta ırk yetişkin köpekler için dengeli, tam beslenme sağlayan kuru mama.',
  },
  {
    'name': 'Yavru Köpek Maması 2 kg',
    'brand': 'Pro Plan',
    'category': 'Köpek',
    'price': 529.0,
    'oldPrice': 619.0,
    'stock': 15,
    'description': 'Büyüme dönemindeki yavru köpekler için protein ve vitamin desteği.',
  },
  {
    'name': 'Kısırlaştırılmış Kedi Maması 2 kg',
    'brand': 'Pro Plan',
    'category': 'Kedi',
    'price': 589.0,
    'stock': 12,
    'description': 'Kısırlaştırılmış kediler için kilo kontrolüne yardımcı kuru mama.',
  },
  {
    'name': 'Yetişkin Kedi Maması 1,5 kg',
    'brand': 'Brit',
    'category': 'Kedi',
    'price': 399.0,
    'oldPrice': 459.0,
    'stock': 25,
    'description': 'Tavuklu, yetişkin kediler için günlük beslenme maması.',
  },
  {
    'name': 'Köpek Ödül Bisküvisi 200 g',
    'brand': "Hill's",
    'category': 'Köpek',
    'price': 189.0,
    'stock': 30,
    'description': 'Eğitim ve ödül anları için çıtır bisküvi.',
  },
  {
    'name': 'Kedi Kumu 10 L',
    'brand': 'Reflex',
    'category': 'Kedi',
    'price': 229.0,
    'oldPrice': 269.0,
    'stock': 18,
    'description': 'Topaklanan, düşük tozlu ve kokuyu tutan kedi kumu.',
  },
  {
    'name': 'Akvaryum Balık Yemi 250 ml',
    'brand': 'Reflex',
    'category': 'Balık',
    'price': 89.0,
    'stock': 40,
    'description': 'Tüm tatlı su balıkları için pul yem.',
  },
  {
    'name': 'Akvaryum İç Filtre Seti',
    'brand': 'Reflex',
    'category': 'Balık',
    'price': 349.0,
    'stock': 8,
    'description': '60 litreye kadar akvaryumlar için sessiz iç filtre.',
  },
  {
    'name': 'Muhabbet Kuşu Yemi 500 g',
    'brand': 'Brit',
    'category': 'Kuş',
    'price': 79.0,
    'stock': 35,
    'description': 'Tohum karışımı, muhabbet kuşları için günlük yem.',
  },
  {
    'name': 'Kuş Oyuncak Seti',
    'brand': 'Reflex',
    'category': 'Kuş',
    'price': 129.0,
    'stock': 10,
    'description': 'Zil, ip ve ahşap parçalardan oluşan 5 parçalı oyuncak seti.',
  },
  {
    'name': 'Köpek Çiğneme Oyuncağı',
    'brand': 'Reflex',
    'category': 'Köpek',
    'price': 119.0,
    'oldPrice': 149.0,
    'stock': 4,
    'description': 'Diş sağlığını destekleyen dayanıklı çiğneme oyuncağı.',
  },
  {
    'name': 'Tahılsız Köpek Maması 2 kg',
    'brand': 'Acana',
    'category': 'Köpek',
    'price': 1099.0,
    'stock': 6,
    'description': 'Tahılsız, yüksek etli tarif; hassas köpekler için.',
  },
];
