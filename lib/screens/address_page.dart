import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import 'auth_page.dart';

class AddressPage extends StatelessWidget {
  const AddressPage({super.key});

  void _openForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: const _AddressForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final addresses = s.profile.addresses;
    final selectedId = s.profile.selectedAddress?.id;

    if (!s.loggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adreslerim')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 56, color: kPrimary),
                const SizedBox(height: 12),
                const Text('Adres eklemek için giriş yap',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  ),
                  child: const Text('Giriş yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Adreslerim')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Adres ekle'),
      ),
      body: addresses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 56, color: kPrimary),
                    SizedBox(height: 12),
                    Text('Kayıtlı adresin yok',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text(
                      'Bir kez ekle, hesabına kaydedilsin; sonraki siparişlerde tekrar yazmana gerek kalmasın.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kMuted),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = addresses[i];
                final selected = a.id == selectedId;
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? kPrimary : kMuted,
                    ),
                    title: Text(a.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(a.summary),
                    trailing: IconButton(
                      tooltip: 'Adresi sil',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => s.removeAddress(a.id),
                    ),
                    onTap: () => s.selectAddress(a.id),
                  ),
                );
              },
            ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm();

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _district = TextEditingController();
  final _details = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _district.dispose();
    _details.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bu alanı doldur' : null;

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AppState>().addAddress(
          title: _title.text.trim(),
          district: _district.text.trim(),
          details: _details.text.trim(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _title,
              validator: _required,
              decoration: const InputDecoration(
                labelText: 'Adres başlığı',
                hintText: 'Ev, İş',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _district,
              validator: _required,
              decoration: const InputDecoration(
                labelText: 'İl / ilçe',
                hintText: 'Ankara / Çankaya',
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _details,
              validator: _required,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açık adres',
                hintText: 'Mahalle, sokak, bina ve daire no',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Adresi kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
