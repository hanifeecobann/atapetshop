import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isFirebaseConfigured) {
    runApp(const SetupErrorApp(
      message:
          'lib/config.dart dosyasındaki Firebase bilgileri henüz doldurulmamış. '
          'Adımlar README.md dosyasında.',
    ));
    return;
  }

  try {
    await Firebase.initializeApp(options: firebaseOptions);
  } catch (e) {
    runApp(SetupErrorApp(message: 'Firebase başlatılamadı: $e'));
    return;
  }

  if (kIsWeb) {
    // Ürünler telefonda önbelleğe alınır: uygulama daha hızlı açılır ve
    // ücretsiz okuma kotası daha az harcanır.
    try {
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: true);
    } catch (_) {}
  }

  final state = AppState();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const PetShopApp(),
    ),
  );
  state.init();
}

class PetShopApp extends StatelessWidget {
  const PetShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'atapetshop',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scaffoldMessengerKey: messengerKey,
      home: const HomeShell(),
    );
  }
}

/// Ayarlar eksikse kullanıcıya ne yapacağını söyler.
class SetupErrorApp extends StatelessWidget {
  final String message;

  const SetupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.settings_suggest_outlined,
                    size: 48, color: kPrimary),
                const SizedBox(height: 16),
                const Text('Kurulum tamamlanmamış',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
