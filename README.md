# Outfitly – AI Virtual Try‑On (Hackathon Edition)

Outfitly, kullanıcı fotoğrafını ve ürün görselini tek tıkla birleştirip fotogerçekçi deneme çıktısı üreten bir demo uygulamadır.

- Flutter istemci (`virtual_try_on_app/`): onboarding, yüklemeler, sonuç ekranı, “Latest outfits”, Adapty paywall (Builder UI + custom fallback).
- Node.js backend (`backend/`): Express API, fal.ai orkestrasyonu, SQLite, statik dosya servis, Cloudflare tünel uyumlu görsel URL’leri.

## Hızlı Kurulum

Önkoşullar
- Flutter 3.35+, Dart 3.9+, Xcode/Android Studio
- Node.js 20+, npm 10+
- (Opsiyonel) cloudflared (tünel için)

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
APP_URL=https://YOUR_TUNNEL.trycloudflare.com
DATABASE_PATH=./data/database.sqlite
STORAGE_PATH=./uploads
FALAI_API_KEY=YOUR_FAL_AI_KEY
FALAI_MODEL=fal-ai/gemini-25-flash-image/edit
```
Cloudflare tünel (ayrı terminal):
```bash
cloudflared tunnel --url http://localhost:3000
```

### 2) Flutter Uygulaması
```bash
cd virtual_try_on_app
flutter pub get
flutter run \
  --dart-define=BACKEND_BASE_URL=https://YOUR_TUNNEL.trycloudflare.com
```
Not: `BACKEND_BASE_URL` her tünel değiştiğinde yeniden verilir. iOS cihazda Safari’den `/health` 200 dönmeli.

## Nasıl Çalışır
1) Kayıt/Giriş (veya misafir) → onboarding → (opsiyonel) Adapty paywall.
2) Kişi fotoğrafını ve ürün görselini yükleyin (kategori seçin).
3) Uygulama backend’e istek atar, backend fal.ai’den görüntüyü oluşturur, görüntüyü indirip `/uploads` altına kaydeder ve herkese açık bir URL döner.
4) Sonuç ekranı ve “Latest outfits” kısmı görseli gösterir; “Like/Dislike” işaretleyebilirsiniz.

## Önemli Detaylar
- Görsel URL’leri: Backend, `APP_URL` localhost olsa bile isteğin `X-Forwarded-Host/Proto` başlıklarını dikkate alarak doğru (tünel) URL’yi döner. Cihazda “localhost” kırık linki olmaz.
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
- 530/502 (Cloudflare):
  - Backend ayakta mı? `curl http://localhost:3000/health`
  - Tünel doğru mu? `cloudflared ...` çıktı adresi ile uygulamadaki `BACKEND_BASE_URL` aynı olmalı.
  - Backend `.env` → `APP_URL` tünel adresi olmalı. Değişince `npm run dev` ile yeniden başlatın.
- Görsel görünmüyor: Backend’i yeniden başlatın; response’taki `image_url` `https://<tünel>/uploads/...` olmalı.
- iOS Paywall görünmüyor: Placement/Builder UI Adapty’de tanımlı mı? Tanımlı değilse uygulama otomatik custom paywall’a düşer.

## Klasör Yapısı
```
virtual_try_on/
├── backend/               # Node.js Express API
└── virtual_try_on_app/    # Flutter client
```

Hackathon için hazır: Tek komutla tünel + backend + app çalışır, demo paywall ile akış hızlı test edilir. Üretime geçerken kimlik doğrulama (JWT vs.), kalıcı depolama (S3/GCS) ve kuyruğa alınmış işleme (BullMQ/Redis) önerilir.
