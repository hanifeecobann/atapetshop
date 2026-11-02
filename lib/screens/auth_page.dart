import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../utils.dart';

/// Giriş yap / kayıt ol.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Bu alanı doldur' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final s = context.read<AppState>();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = _register
        ? await s.signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            phone: _phone.text,
          )
        : await s.signIn(_email.text, _password.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Önce e-posta adresini yaz.');
      return;
    }
    final error = await context.read<AppState>().resetPassword(_email.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
    } else {
      showMsg('Şifre yenileme bağlantısı e-postana gönderildi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          const Icon(Icons.pets, size: 44, color: kPrimary),
          const SizedBox(height: 12),
          Text(
            _register ? 'Hesap oluştur' : 'Tekrar hoş geldin',
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600, color: kInk),
          ),
          const SizedBox(height: 4),
          Text(
            _register
                ? 'Adreslerin, favorilerin ve siparişlerin hesabında saklanır.'
                : 'Giriş yap, kayıtlı adreslerin ve siparişlerin seni bekliyor.',
            style: const TextStyle(color: kMuted),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                if (_register) ...[
                  TextFormField(
                    controller: _name,
                    validator: _required,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Ad soyad', hintText: 'Ayşe Yılmaz'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    validator: (v) =>
                        (v == null || v.replaceAll(RegExp(r'\D'), '').length < 10)
                            ? 'Geçerli bir telefon numarası gir'
                            : null,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        labelText: 'Telefon', hintText: '05xx xxx xx xx'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _email,
                  validator: _required,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                      labelText: 'E-posta', hintText: 'ad@ornek.com'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Şifre en az 6 karakter olmalı'
                      : null,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    suffixIcon: IconButton(
                      icon: Icon(_hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFB3261E))),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_register ? 'Kayıt ol' : 'Giriş yap'),
          ),
          if (!_register)
            TextButton(
              onPressed: _forgot,
              child: const Text('Şifremi unuttum'),
            ),
          TextButton(
            onPressed: () => setState(() {
              _register = !_register;
              _error = null;
            }),
            child: Text(_register
                ? 'Zaten hesabın var mı? Giriş yap'
                : 'Hesabın yok mu? Kayıt ol'),
          ),
        ],
      ),
    );
  }
}
