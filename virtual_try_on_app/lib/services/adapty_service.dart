import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdaptyService {
  AdaptyService(this._adapty);

  final Adapty _adapty;

  Future<void> initialise({required String apiKey}) async {
    final isActivated = await _adapty.isActivated();
    if (!isActivated) {
      await _adapty.activate(
        configuration: AdaptyConfiguration(apiKey: apiKey),
      );
    }
    if (kDebugMode) {
      AdaptyLogger.logLevel = AdaptyLogLevel.verbose;
      await _adapty.setLogLevel(AdaptyLogLevel.verbose);
    }
  }

  Future<AdaptyPaywall?> getDefaultPaywall({
    required String placementId,
  }) async {
    try {
      final paywall = await _adapty.getPaywallForDefaultAudience(
        placementId: placementId,
      );
      await _adapty.logShowPaywall(paywall: paywall);
      return paywall;
    } on AdaptyError catch (error) {
      debugPrint('Adapty paywall error: ${error.message}');
      return null;
    }
  }

  Future<List<AdaptyPaywallProduct>> getPaywallProducts(
    AdaptyPaywall paywall,
  ) async {
    try {
      return await _adapty.getPaywallProducts(paywall: paywall);
    } on AdaptyError catch (error) {
      debugPrint('Adapty products error: ${error.message}');
      return const <AdaptyPaywallProduct>[];
    }
  }

  Future<bool> purchase(AdaptyPaywallProduct product) async {
    try {
      await _adapty.makePurchase(product: product);
      return true;
    } on AdaptyError catch (error) {
      debugPrint('Purchase failed: ${error.message}');
      return false;
    }
  }
}

final adaptyServiceProvider = Provider<AdaptyService>((ref) {
  return AdaptyService(Adapty());
});
