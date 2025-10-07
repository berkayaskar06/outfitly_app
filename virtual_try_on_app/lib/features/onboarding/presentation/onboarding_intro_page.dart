import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingIntroPage extends ConsumerWidget {
  const OnboardingIntroPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Getting Started')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '👔 AI Stilist Asistanınız',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Fotoğrafınızı ürün görselleriyle eşleştirerek anlık kıyafet denemeleri yapın. AI teknolojimiz vücut oranlarınızı ve kumaş detaylarını koruyarak güvenle alışveriş yapmanızı sağlar.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: const <Widget>[
                    _IntroPoint(
                      icon: Icons.flash_on,
                      title: '⚡ Hızlı Deneme',
                      subtitle:
                          'Stüdyo randevusuna gerek kalmadan saniyeler içinde stil önerileri alın.',
                    ),
                    _IntroPoint(
                      icon: Icons.auto_awesome,
                      title: '✨ Kişiselleştirilmiş',
                      subtitle:
                          'Ölçülerinize ve tarz tercihinize göre optimize edilmiş öneriler.',
                    ),
                    _IntroPoint(
                      icon: Icons.favorite,
                      title: '❤️ Favorilerinizi Saklayın',
                      subtitle:
                          'Beğendiğiniz kombinleri kaydedip istediğiniz zaman erişin.',
                    ),
                    _IntroPoint(
                      icon: Icons.shield_outlined,
                      title: '🔒 Gizliliğiniz Güvende',
                      subtitle:
                          'Görselleriniz şifrelenmiş şekilde saklanır, istediğiniz zaman silebilirsiniz.',
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () => context.go('/onboarding/demographics'),
                  child: const Text(
                    'Başlayalım 🚀',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPoint extends StatelessWidget {
  const _IntroPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
