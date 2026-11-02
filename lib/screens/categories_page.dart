import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/product_card.dart';

/// Kategoriler + marka kataloğu + arama.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _open(BuildContext context, String title, bool Function(Product) filter) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListPage(title: title, filter: filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final products = s.products;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _ctrl,
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Mama, oyuncak, marka ara',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _q = '');
                        },
                      ),
              ),
            ),
          ),
          if (_q.isNotEmpty)
            Expanded(child: _searchResults(products))
          else ...[
            const TabBar(
              labelColor: kPrimaryDark,
              indicatorColor: kPrimary,
              tabs: [Tab(text: 'Kategoriler'), Tab(text: 'Markalar')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _categoryList(context, products),
                  _brandGrid(context, s.brands, products),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _searchResults(List<Product> products) {
    final items = products.where((p) {
      final hay = '${p.name} ${p.brand} ${p.category}'.toLowerCase();
      return hay.contains(_q);
    }).toList();
    if (items.isEmpty) {
      return const Center(
        child: Text('Sonuç bulunamadı.', style: TextStyle(color: kMuted)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: productGridDelegate,
      itemCount: items.length,
      itemBuilder: (context, i) => ProductCard(product: items[i]),
    );
  }

  Widget _categoryList(BuildContext context, List<Product> products) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final c in kCategories)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: kTint,
                  child: Icon(c.icon, color: kPrimaryDark),
                ),
                title: Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    '${products.where((p) => p.category == c.name).length} ürün'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, c.name, (p) => p.category == c.name),
              ),
            ),
          ),
      ],
    );
  }

  Widget _brandGrid(
      BuildContext context, List<String> brands, List<Product> products) {
    if (brands.isEmpty) {
      return const Center(
        child: Text('Markalar ürünler eklenince burada görünecek.',
            style: TextStyle(color: kMuted)),
      );
    }
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.1,
      children: [
        for (final b in brands)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _open(context, b, (p) => p.brand == b),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(b,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: kInk)),
                    Text(
                      '${products.where((p) => p.brand == b).length} ürün',
                      style: const TextStyle(fontSize: 11, color: kMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Bir kategori ya da markanın ürünlerini listeler.
/// Liste canlı olduğu için yönetici bir şeyi değiştirince burada da güncellenir.
class ProductListPage extends StatelessWidget {
  final String title;
  final bool Function(Product) filter;

  const ProductListPage({super.key, required this.title, required this.filter});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<AppState>().products.where(filter).toList();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: products.isEmpty
          ? const Center(
              child: Text('Bu bölümde henüz ürün yok.',
                  style: TextStyle(color: kMuted)),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: productGridDelegate,
              itemCount: products.length,
              itemBuilder: (context, i) => ProductCard(product: products[i]),
            ),
    );
  }
}
