# atapetshop: iPhone'a kurulan, tamamen ücretsiz mağaza uygulaması

Müşteri uygulaması ve yönetim paneli tek uygulamada. iPhone'da Safari'den "Ana Ekrana Ekle" ile kurulur, tam ekran açılır, simgesi telefondadır. App Store, Mac ya da Apple geliştirici ücreti gerekmez.

**Müşteri:** kayıt/giriş, ana sayfa, kategori + marka kataloğu + arama, favoriler, sepet, kayıtlı adresler, kapıda ödemeli sipariş, sipariş geçmişi ve canlı durum, teslimat ücreti ve minimum sepet kuralı, stok uyarıları, mağazaya yol tarifi (iPhone'da Apple Haritalar).

**Yönetici:** gelen siparişleri görme ve durum güncelleme, stok adedi ve otomatik stok düşme, ürün ekleme/düzenleme/silme, fotoğraf yükleme, tekil ve toplu indirim, ana sayfa duyurusu, mağaza adı/telefon/konum, teslimat ücreti, ücretsiz teslimat sınırı, minimum sepet tutarı.

## Neden bu yöntem ücretsiz?

| Parça | Servis | Ücret |
|---|---|---|
| Hesaplar | Firebase Authentication | Ücretsiz, kart gerekmez |
| Ürün, sipariş, adres verileri | Firebase Firestore (Spark planı) | Ücretsiz günlük kota: 50.000 okuma, 20.000 yazma, 1 GiB. Kota dolarsa fatura gelmez, uygulama ertesi güne kadar yavaşlar/durur |
| Ürün fotoğrafları | Cloudinary ücretsiz plan | Ayda 25 kredi, kart gerekmez |
| Uygulamanın yayını | GitHub Pages (herkese açık depo) | Ücretsiz |

Kullanılmayanlar: Firebase Storage (Şubat 2026'dan beri ücretli plan istiyor) ve Cloud Functions (ücretli plan gerekiyor). Bu yüzden fotoğraflar Cloudinary'de, bildirimler uygulama içinde.

## Kurulum (yaklaşık 30 dakika)

### 1. Firebase (ücretsiz Spark planı)

1. [console.firebase.google.com](https://console.firebase.google.com) > **Proje ekle**. Analytics'i kapatabilirsin. Plan olarak Spark'ta kal, faturalandırma ekleme.
2. **Build > Authentication** > Başlayın > **E-posta/Şifre**'yi etkinleştir.
3. **Build > Firestore Database** > Veritabanı oluştur > **Üretim modunda başlat**, konum olarak Avrupa'dan birini seç (ör. `eur3`).
4. Firestore > **Kurallar** sekmesi: bu paketteki `firestore.rules` dosyasının içeriğini yapıştır > **Yayınla**.
5. Proje ayarları (dişli) > **Uygulamalarım** > `</>` (Web) simgesi > uygulama adı `atapetshop` > Kaydet. Çıkan `firebaseConfig` bilgilerini `lib/config.dart` dosyasındaki yerlere yaz: `apiKey`, `appId`, `messagingSenderId`, `projectId`, `authDomain`.

### 2. Cloudinary (ücretsiz fotoğraf servisi)

1. [cloudinary.com](https://cloudinary.com) > ücretsiz hesap aç (kart istemez). Dashboard'daki **Cloud name** değerini `lib/config.dart` > `kCloudinaryCloudName` alanına yaz.
2. **Settings > Upload > Upload presets > Add upload preset**:
   - Signing mode: **Unsigned**
   - Folder: `atapetshop`
   - Allowed formats: `jpg,png,webp`
   - Incoming transformation: genişlik en fazla 1200 px (Limit), quality auto
3. Preset adını `lib/config.dart` > `kCloudinaryUploadPreset` alanına yaz.

### 3. GitHub ile yayınlama (kendi bilgisayarına Flutter kurmadan)

1. [github.com](https://github.com) > ücretsiz hesap > **New repository** (ör. `atapetshop`), **Public** seç.
2. Bu klasörün tüm içeriğini depoya yükle. Terminalden:

```
git init
git add .
git commit -m "ilk sürüm"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADIN/atapetshop.git
git push -u origin main
```

   (`.github` gizli klasörü de gitmeli, uygulamayı otomatik derleyen o.)
3. Depoda **Settings > Pages > Build and deployment > Source: GitHub Actions** seç.
4. **Actions** sekmesinde "Yayınla" işinin yeşile dönmesini bekle (3-6 dakika). Hata olursa kırmızı adımın günlüğünü bana yapıştır.
5. Adresin: `https://KULLANICI_ADIN.github.io/atapetshop/`
6. Firebase > Authentication > **Settings > Authorized domains** > **Add domain** > `KULLANICI_ADIN.github.io` ekle (yoksa giriş çalışmaz).

Her `git push` uygulamayı kendiliğinden günceller.

### 4. iPhone'a kurma

1. iPhone'da **Safari**'yi aç, yukarıdaki adrese git.
2. Alttaki **Paylaş** simgesine bas > **Ana Ekrana Ekle** > Ekle.
3. Ana ekranındaki atapetshop simgesinden aç. Tam ekran, uygulama gibi çalışır. Müşterilerine de aynı adresi ya da QR kodunu ver.

### 5. İlk yönetici hesabı

1. Uygulamada kendi e-postanla **kayıt ol**.
2. Firebase Console > Authentication > Users > hesabının **Kullanıcı UID** değerini kopyala.
3. Firestore > **Koleksiyon başlat** > `admins` > Belge kimliği: o UID > bir alan ekle (ör. `role` = `admin`) > Kaydet.
4. Uygulamadan çıkış yapıp tekrar gir. **Hesabım** sayfasında "Yönetim paneli" görünür.

### 6. İlk ayarlar (Yönetim paneli)

1. **Mağaza** sekmesi: adı, telefonu, konumu, teslimat ücretini, ücretsiz teslimat sınırını ve minimum sepet tutarını gir > Kaydet. (Hepsi 0 ise teslimat ücretsiz ve sepet sınırı yoktur.)
2. **Ürünler** sekmesi: ürün ekle (fotoğraf, fiyat, stok adedi) ya da "Örnek ürünleri yükle" ile denemeye başla.

## Nasıl çalışıyor?

- **Sipariş:** Müşteri sepeti onaylar, ödeme kapıda yapılır. Sipariş yönetici panelinde anında görünür. Panel açıkken yeni sipariş gelince ses çalar ve ekranda uyarı çıkar.
- **Stok:** Sipariş "Hazırlanıyor" (ya da Yolda/Teslim edildi) olunca ürün stokları siparişteki adet kadar düşer. "İptal" olursa geri eklenir. Stok yetmeyen siparişte panel uyarır. Müşteri sepete stoktan fazla ekleyemez.
- **Teslimat:** Sepet ücretsiz teslimat sınırına ulaşırsa ücret sıfırlanır; sepet ekranı "X ₺ daha ekle, teslimat ücretsiz olsun" der. Minimum tutarın altında sipariş verilemez.
- **Fiyat güvenliği:** Siparişteki tutar yönetici panelinde güncel fiyatlarla karşılaştırılır, uyuşmazsa kırmızı uyarı çıkar.
- **Duyuru / indirim:** "Toplu indirim"i uygularken "Ana sayfada duyuru yayınla"yı işaretlersen müşterilerin ana sayfasında duyuru görünür. Duyuruyu Duyuru sekmesinden de yazabilirsin.

## Ücretsiz planın sınırları (bilerek)

- **Uygulama kapalıyken bildirim gelmez.** Ücretsiz planda sunucu tarafı yok, bu yüzden telefona anlık bildirim (push) gönderemiyoruz. Yeni siparişi duymak için yönetim panelinin açık olduğu bir telefon/tablet kullan (mağazada açık bırakabilirsin). Müşteriler sipariş durumunu uygulamayı açınca canlı görür.
- **Fotoğraf silme:** Ürünü silsen bile Cloudinary'deki dosya kalır. Ücretsiz kotada sorun olmaz, istersen Cloudinary panelinden elle silebilirsin.
- **Kota:** Çok yoğun günde Firestore günlük kotası dolabilirse uygulama ertesi güne kadar yavaşlar. Bu olursa Firebase'de Blaze planına geçmek tek çözümdür; geçmediğin sürece fatura çıkmaz.
- **Gerçek kart ödemesi** yok, ödeme kapıda alınır.
- **Apple App Store** için Mac ve yıllık Apple geliştirici üyeliği gerekir, ücretsiz değildir. Bu web uygulaması iPhone'da tam ekran çalışır ve tek kod tabanı Android'de de aynı adresten kurulur (Chrome > Ana ekrana ekle).

## Kendi bilgisayarında denemek (isteğe bağlı)

Flutter kuruluysa: `flutter pub get` ve `flutter run -d chrome`.
