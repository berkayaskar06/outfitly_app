# Outfitly – AI Virtual Try‑On (Hackathon Edition)

Outfitly, kullanıcı fotoğrafını ve ürün görselini tek tıkla birleştirip fotogerçekçi deneme çıktısı üreten bir demo uygulamadır.

- Flutter istemci (`virtual_try_on_app/`): onboarding, yüklemeler, sonuç ekranı, “Latest outfits”, Adapty paywall (Builder UI + custom fallback).
- Node.js backend (`backend/`): Express API, fal.ai orkestrasyonu, SQLite, statik dosya servis, Cloudflare tünel uyumlu görsel URL’leri.

## Hızlı Kurulum

Önkoşullar
- Flutter 3.35+, Dart 3.9+, Xcode/Android Studio
- Node.js 20+, npm 10+
  

### 1) Backend
```bash
cd backend
cp .env.example .env
npm install
npm run dev
# Sağlık kontrolü
curl http://localhost:3000/health
```
.env örneği (güncelleyin):
```
PORT=3000
APP_URL=http://localhost:3000
DATABASE_PATH=./data/database.sqlite
STORAGE_PATH=./uploads
FALAI_API_KEY=YOUR_FAL_AI_KEY
FALAI_MODEL=fal-ai/gemini-25-flash-image/edit
```
Not: Yarışma testi için tünel gerekmiyor; backend doğrudan localhost:3000 üzerinden çalışır.

### 2) Flutter Uygulaması
```bash
cd virtual_try_on_app
flutter pub get
flutter run --dart-define=BACKEND_BASE_URL=http://localhost:3000
```
Not: Cihaz gerçek cihaz ise bilgisayarın IP’sini verin: `http://192.168.x.x:3000`.

## Nasıl Çalışır
1) Kayıt/Giriş (veya misafir) → onboarding → (opsiyonel) Adapty paywall.
2) Kişi fotoğrafını ve ürün görselini yükleyin (kategori seçin).
3) Uygulama backend’e istek atar, backend fal.ai’den görüntüyü oluşturur, görüntüyü indirip `/uploads` altına kaydeder ve herkese açık bir URL döner.
4) Sonuç ekranı ve “Latest outfits” kısmı görseli gösterir; “Like/Dislike” işaretleyebilirsiniz.

## Önemli Detaylar
- Görsel URL’leri: Lokal testte `APP_URL=http://localhost:3000` yeterlidir.
- Yükleme limiti: Multer 20 MB (iPhone fotoğrafları için güvenli).
- Adapty: `virtual_try_on_app/lib/utils/constants.dart` içinde `adaptyApiKey` ve `adaptyPaywallPlacementId` ayarlayın. Demo mod (`enableDemoPaywall=true`) açıkken paywall CTA’sı onboarding’i geçer.
- Base URL: `AppConfig.backendBaseUrl` derleme anında `--dart-define` ile gelir (tünel değiştikçe komutu yeniden verin).

## API Kısa Özeti
- `POST /api/persons` — `image` (multipart)
- `POST /api/products` — `image`, `category`
- `GET /api/prompts?category=...`
- `POST /api/try-on` — `person_id`, `product_id`, `prompt`
- `GET /api/try-on/:id` — durum + `image_url`

## Sorun Giderme
- Bağlantı sorunları:
  - Backend ayakta mı? `curl http://localhost:3000/health`
  - Mobil cihazdan testte base URL’i bilgisayar IP’siyle verin.
- Görsel görünmüyor: Backend’i yeniden başlatın; response’taki `image_url` `https://<tünel>/uploads/...` olmalı.
- iOS Paywall görünmüyor: Placement/Builder UI Adapty’de tanımlı mı? Tanımlı değilse uygulama otomatik custom paywall’a düşer.

## Klasör Yapısı
```
virtual_try_on/
├── backend/               # Node.js Express API
└── virtual_try_on_app/    # Flutter client
```

Hackathon için hazır: Tek komutla tünel + backend + app çalışır, demo paywall ile akış hızlı test edilir. Üretime geçerken kimlik doğrulama (JWT vs.), kalıcı depolama (S3/GCS) ve kuyruğa alınmış işleme (BullMQ/Redis) önerilir.
