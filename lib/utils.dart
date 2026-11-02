import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Uygulama genelinde SnackBar göstermek için (context gerektirmez).
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void showMsg(String text) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
}

/// 749 -> "749 ₺", 89.9 -> "89,90 ₺"
String tl(double v) {
  final whole = v == v.roundToDouble();
  final s = v.toStringAsFixed(whole ? 0 : 2).replaceAll('.', ',');
  return '$s ₺';
}

String formatDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

double? parseNumber(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// iPhone'da Apple Haritalar, diğerlerinde Google Haritalar açılır.
Future<void> openDirections(double lat, double lng) async {
  final apple = defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
  final uri = apple
      ? Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d')
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) showMsg('Harita uygulaması açılamadı.');
  } catch (_) {
    showMsg('Harita uygulaması açılamadı.');
  }
}

Future<void> callPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  try {
    final ok = await launchUrl(uri);
    if (!ok) showMsg('Arama başlatılamadı.');
  } catch (_) {
    showMsg('Arama başlatılamadı.');
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Yeni':
      return const Color(0xFFE76F51);
    case 'Hazırlanıyor':
      return const Color(0xFFC98A1B);
    case 'Yolda':
      return const Color(0xFF3B82C4);
    case 'Teslim edildi':
      return const Color(0xFF1B6B62);
    default:
      return const Color(0xFF6B7C79);
  }
}
