import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';
import 'address_page.dart';
import 'admin_page.dart';
import 'auth_page.dart';
import 'orders_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _editProfile(BuildContext context, AppState s) async {
    final name = TextEditingController(text: s.profile.name);
    final phone = TextEditingController(text: s.profile.phone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bilgilerim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad soyad'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final newName = name.text;
    final newPhone = phone.text;
    name.dispose();
    phone.dispose();
    if (ok == true) {
      await s.updateProfile(name: newName, phone: newPhone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();

    if (!s.loggedIn) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.account_circle_outlined, size: 64, color: kPrimary),
          const SizedBox(height: 12),
          const Text('Hesabına giriş yap',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Adreslerin, favorilerin ve önceki siparişlerin hesabında saklanır; telefon değiştirsen bile kaybolmaz.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kMuted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthPage()),
            ),
            child: const Text('Giriş yap / Kayıt ol'),
          ),
          const SizedBox(height: 16),
          _Section([
            ListTile(
              leading:
                  const Icon(Icons.directions_outlined, color: kPrimaryDark),
              title: const Text('Mağazaya yol tarifi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openDirections(s.store.lat, s.store.lng),
            ),
          ]),
        ],
      );
    }

    final name = s.profile.name.isEmpty ? 'Hoş geldin' : s.profile.name;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: kTint,
              child: Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryDark),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(s.profile.email,
                      style: const TextStyle(fontSize: 12, color: kMuted)),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 28),
                      alignment: Alignment.centerLeft,
                    ),
                    onPressed: () => _editProfile(context, s),
                    child: const Text('Bilgilerimi düzenle'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (s.isAdmin) ...[
          Material(
            color: kPrimary,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Colors.white),
              title: const Text('Yönetim paneli',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${s.allOrders.where((o) => o.status == 'Yeni').length} yeni sipariş',
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _Section([
          ListTile(
            leading:
                const Icon(Icons.location_on_outlined, color: kPrimaryDark),
            title: const Text('Adreslerim'),
            subtitle: Text(s.profile.addresses.isEmpty
                ? 'Henüz adres eklemedin'
                : '${s.profile.addresses.length} kayıtlı adres'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddressPage()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading:
                const Icon(Icons.receipt_long_outlined, color: kPrimaryDark),
            title: const Text('Siparişlerim'),
            subtitle: Text(s.myOrders.isEmpty
                ? 'Henüz siparişin yok'
                : '${s.myOrders.length} sipariş'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersPage()),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        _Section([
          ListTile(
            leading:
                const Icon(Icons.directions_outlined, color: kPrimaryDark),
            title: const Text('Mağazaya yol tarifi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => openDirections(s.store.lat, s.store.lng),
          ),
        ]),
        const SizedBox(height: 12),
        _Section([
          ListTile(
            leading: const Icon(Icons.logout, color: kPrimaryDark),
            title: const Text('Çıkış yap'),
            onTap: s.signOut,
          ),
        ]),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section(this.children);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
