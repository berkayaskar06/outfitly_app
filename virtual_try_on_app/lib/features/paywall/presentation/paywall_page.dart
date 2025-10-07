import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/constants.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallsObserver extends AdaptyUIPaywallsEventsObserver {
  _PaywallsObserver({required this.onDismiss});
  final VoidCallback onDismiss;

  @override
  void paywallViewDidDisappear(AdaptyUIPaywallView view) {
    onDismiss();
  }

  @override
  void paywallViewDidFinishPurchase(
    AdaptyUIPaywallView view,
    AdaptyPaywallProduct product,
    AdaptyPurchaseResult purchaseResult,
  ) {
    view.dismiss();
  }

  @override
  void paywallViewDidStartPurchase(
    AdaptyUIPaywallView view,
    AdaptyPaywallProduct product,
  ) {
    if (AppConfig.enableDemoPaywall) {
      view.dismiss();
      onDismiss();
    }
  }

  @override
  void paywallViewDidFinishRestore(
    AdaptyUIPaywallView view,
    AdaptyProfile profile,
  ) {
    view.dismiss();
  }

  @override
  void paywallViewDidFailRendering(AdaptyUIPaywallView view, AdaptyError error) {}
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  AdaptyPaywall? _paywall;
  List<AdaptyPaywallProduct> _products = [];
  bool _isLoading = true;
  String? _error;
  AdaptyPaywallProduct? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadPaywall();
  }

  Future<void> _loadPaywall() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch paywall for placement
      final paywall = await Adapty().getPaywallForDefaultAudience(
        placementId: AppConfig.adaptyPaywallPlacementId,
      );

      if (paywall != null) {
        await Adapty().logShowPaywall(paywall: paywall);

        // Eğer Paywall Builder konfigürasyonu varsa AdaptyUI ile göster
        if (paywall.hasViewConfiguration == true) {
          try {
            final view = await AdaptyUI().createPaywallView(paywall: paywall);
            AdaptyUI().setPaywallsEventsObserver(
              _PaywallsObserver(onDismiss: () => context.go('/')),
            );
            await AdaptyUI().presentPaywallView(view);
            if (mounted) {
              setState(() => _isLoading = false);
            }
            return;
          } catch (e) {
            debugPrint('AdaptyUI presentPaywallView error: $e');
            // Devamında custom UI'ya düşeceğiz
          }
        }

        // Builder yoksa veya hata aldıysa ürünleri çekip custom UI göster
        final products = await Adapty().getPaywallProducts(paywall: paywall);

        setState(() {
          _paywall = paywall;
          _products = products;
          _selectedProduct = products.isNotEmpty ? products.first : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Paywall bulunamadı';
          _isLoading = false;
        });
      }
    } on AdaptyError catch (e) {
      // Demo fallback: ürünler yoksa sahte ürün ile devam
      if (AppConfig.enableDemoPaywall) {
        setState(() {
          _paywall = null;
          _products = [];
          _selectedProduct = null;
          _isLoading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _error = e.message ?? 'Bir hata oluştu';
        _isLoading = false;
      });
      debugPrint('Adapty error: ${e.message}');
    } catch (e) {
      setState(() {
        _error = 'Beklenmeyen bir hata oluştu';
        _isLoading = false;
      });
      debugPrint('Error loading paywall: $e');
    }
  }

  Future<void> _handlePurchase() async {
    if (_selectedProduct == null) return;

    setState(() => _isLoading = true);

    try {
      await Adapty().makePurchase(product: _selectedProduct!);

      // Purchase successful
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Satın alma başarılı!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home
      context.go('/');
    } on AdaptyError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Satın alma başarısız: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final profile = await Adapty().getProfile();
      final hasAccess = profile.accessLevels['premium']?.isActive ?? false;

      if (!mounted) return;

      if (hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Premium aboneliğiniz geri yüklendi!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktif abonelik bulunamadı'),
          ),
        );
      }
    } on AdaptyError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Geri yükleme başarısız: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? _ErrorView(
                    error: _error!,
                    onRetry: _loadPaywall,
                    onClose: () => context.go('/'),
                  )
                : (_products.isEmpty && AppConfig.enableDemoPaywall)
                    ? _DemoPaywall(onClose: () => context.go('/'))
                    : _PaywallContent(
                    products: _products,
                    selectedProduct: _selectedProduct,
                    onProductSelected: (product) {
                      setState(() => _selectedProduct = product);
                    },
                    onPurchase: _handlePurchase,
                    onRestore: _restorePurchases,
                    onClose: () => context.go('/'),
                  ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.error,
    required this.onRetry,
    required this.onClose,
  });

  final String error;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClose,
              child: const Text('Kapat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaywallContent extends StatelessWidget {
  const _PaywallContent({
    required this.products,
    required this.selectedProduct,
    required this.onProductSelected,
    required this.onPurchase,
    required this.onRestore,
    required this.onClose,
  });

  final List<AdaptyPaywallProduct> products;
  final AdaptyPaywallProduct? selectedProduct;
  final ValueChanged<AdaptyPaywallProduct> onProductSelected;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),

        // Header
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 56,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Outfitly Premium',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                const Text(
                  'Sınırsız AI deneme ve premium özellikler',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Features
                ...[
                  _FeatureItem(
                    icon: Icons.auto_fix_high,
                    title: 'Sınırsız AI Try-On',
                    description: 'Dilediğiniz kadar kıyafet deneyin',
                  ),
                  _FeatureItem(
                    icon: Icons.hd,
                    title: 'Yüksek Kalite',
                    description: 'HD kalitede çıktı görüntüleri',
                  ),
                  _FeatureItem(
                    icon: Icons.favorite,
                    title: 'Favori Kombinler',
                    description: 'Sınırsız favori kaydı',
                  ),
                  _FeatureItem(
                    icon: Icons.speed,
                    title: 'Öncelikli İşlem',
                    description: 'Daha hızlı AI işleme',
                  ),
                  _FeatureItem(
                    icon: Icons.cloud_off,
                    title: 'Reklamsız Deneyim',
                    description: 'Hiç reklam görmeden kullanın',
                  ),
                ],

                const SizedBox(height: 32),

                // Products
                if (products.isNotEmpty) ...[
                  ...products.map((product) => _ProductCard(
                        product: product,
                        isSelected: selectedProduct?.vendorProductId ==
                            product.vendorProductId,
                        onTap: () => onProductSelected(product),
                      )),
                  const SizedBox(height: 16),
                ],

                // Purchase button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedProduct == null ? null : onPurchase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Premium\'a Geç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Restore button
                TextButton(
                  onPressed: onRestore,
                  child: const Text(
                    'Satın Alımları Geri Yükle',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),

                const SizedBox(height: 8),

                // Terms
                const Text(
                  'Premium abonelik otomatik olarak yenilenir. İstediğiniz zaman iptal edebilirsiniz.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoPaywall extends StatelessWidget {
  const _DemoPaywall({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                const Icon(Icons.lock_open, color: Colors.white, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'Demo Premium Etkin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mağaza ürünleri hazır olmadığı için demo modda devam ediyorsunuz. Tüm premium özellikler bu oturum için açık.',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Devam Et',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isSelected,
    required this.onTap,
  });

  final AdaptyPaywallProduct product;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = _getTitleForProduct(product);
    final price = product.price?.localizedString ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
              : const Color(0xFF2D2D44),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sade görünüm: dönem bilgisini göstermiyoruz
  String _getTitleForProduct(AdaptyPaywallProduct product) {
    // SDK farklı sürümlerde başlık alanı değişebildiği için güvenli seçim
    // Müsait alan yoksa vendorProductId gösterilir
    try {
      // ignore: avoid_dynamic_calls
      final dynamic maybeTitle = (product as dynamic).localizedTitle;
      if (maybeTitle is String && maybeTitle.trim().isNotEmpty) {
        return maybeTitle;
      }
    } catch (_) {}
    return 'Ürün: ${product.vendorProductId}';
  }
}
