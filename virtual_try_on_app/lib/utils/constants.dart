class AppConfig {
  const AppConfig._();

  // Yarışma testi için localhost kullanımı
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String adaptyApiKey = 'public_live_zmlzwKkz.BICml7z3O3Wsht4mzFA0';
  // Adapty Dashboard → Placements → canlıda kullandığınız placement id
  static const String adaptyPaywallPlacementId = 'outfitly_premium';
  // Demo: App Store/Adapty ürünleri hazır değilse sahte paywall kullan
  static const bool enableDemoPaywall = true;
  static const String falApiModel = 'fal-ai/try-on/v1';
}
