import 'package:firebase_core/firebase_core.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAVG_C2SmtjSkhDqX7K6jQ9Oa3OSBBPc0U',
  appId: '1:547497476056:web:939527876b43edb942bcad',
  messagingSenderId: '547497476056',
  projectId: 'atapetshop-1a0dd',
  authDomain: 'atapetshop-1a0dd.firebaseapp.com',
);

/// Cloudinary (ücretsiz fotoğraf servisi). Şimdilik boş kalabilir,
/// ürünleri fotoğrafsız ekleyip uygulamayı deneyebilirsin.
const String kCloudinaryCloudName = 'BURAYA_cloudName';
const String kCloudinaryUploadPreset = 'BURAYA_uploadPreset';

bool get isFirebaseConfigured => !firebaseOptions.apiKey.startsWith('BURAYA');

bool get isCloudinaryConfigured =>
    !kCloudinaryCloudName.startsWith('BURAYA') &&
    !kCloudinaryUploadPreset.startsWith('BURAYA');