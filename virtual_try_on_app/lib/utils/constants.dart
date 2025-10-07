class AppConfig {
  const AppConfig._();

  // Force localhost for all requests (ignore dart-define)
  static const String backendBaseUrl = 'http://localhost:3000';
  static const String adaptyApiKey = 'public_live_zmlzwKkz.BICml7z3O3Wsht4mzFA0';
  // Adapty Dashboard → Placements → canlıda kullandığınız placement id
  static const String adaptyPaywallPlacementId = 'outfitly_premium';
  // Ücretsiz deneme paywall placement id (Adapty Dashboard'da oluşturuldu)
  static const String adaptyFreeTrialPlacementId = 'outfitly_free_trial';
  // Ücretsiz deneme hakkı
  static const int freeTrialTryOnLimit = 5;
  // Demo: App Store/Adapty ürünleri hazır değilse sahte paywall kullan (kapalı)
  static const bool enableDemoPaywall = false;
  static const String falApiModel = 'fal-ai/try-on/v1';
}
