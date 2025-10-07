import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/constants.dart';

import '../../../models/user_profile.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/application/library_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final library = ref.watch(libraryControllerProvider);
    final profile = authState.profile ?? UserProfile.guest();
    final subscriptionActive = profile.subscriptionActive;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(profile.fullName.characters.first.toUpperCase()),
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(profile.email, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            FutureBuilder<int>(
              future: _loadUsedTryOnCount(),
              builder: (context, snapshot) {
                final used = snapshot.data ?? 0;
                final remaining = (AppConfig.freeTrialTryOnLimit - used).clamp(0, AppConfig.freeTrialTryOnLimit);
                final subtitle = subscriptionActive
                    ? 'Unlimited try-ons and wardrobe history.'
                    : 'Free trial: $remaining of ${AppConfig.freeTrialTryOnLimit} try-ons remaining';
                return Card(
                  child: ListTile(
                    leading: Icon(
                      subscriptionActive ? Icons.verified : Icons.lock_outline,
                    ),
                    title: Text(
                      subscriptionActive ? 'Premium active' : 'Free plan',
                    ),
                    subtitle: Text(subtitle),
                    trailing: TextButton(
                      onPressed: () => context.push('/paywall'),
                      child: Text(subscriptionActive ? 'Manage' : 'Upgrade'),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _StatRow(
              title: 'Uploads',
              value:
                  '${library.persons.length} persons / ${library.products.length} garments',
            ),
            _StatRow(
              title: 'Outfits generated',
              value: library.results.length.toString(),
            ),
            const SizedBox(height: 24),
            Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (profile.gender != null)
              _DetailTile(
                title: 'Gender',
                value: _genderLabel(profile.gender!),
              ),
            if (profile.ageRange != null)
              _DetailTile(title: 'Age range', value: profile.ageRange!),
            if (profile.stylePreferences.isNotEmpty)
              _DetailTile(
                title: 'Styles',
                value: profile.stylePreferences.join(', '),
              ),
            const SizedBox(height: 24),
            Text(
              'Privacy & legal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: const <Widget>[
                  _LinkTile(
                    title: 'Privacy policy',
                    url: 'https://virtualtryon.app/privacy',
                  ),
                  Divider(height: 1),
                  _LinkTile(
                    title: 'Terms of use',
                    url: 'https://virtualtryon.app/terms',
                  ),
                  Divider(height: 1),
                  _LinkTile(
                    title: 'Data deletion request',
                    url: 'https://virtualtryon.app/support',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: authState.status == AuthStatus.authenticated
                  ? () => ref.read(authControllerProvider.notifier).logout()
                  : null,
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }

  String _genderLabel(Gender gender) {
    switch (gender) {
      case Gender.female:
        return 'Female';
      case Gender.male:
        return 'Male';
      case Gender.nonBinary:
        return 'Non-binary';
    }
  }
}

Future<int> _loadUsedTryOnCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('used_try_on_count') ?? 0;
  } catch (_) {
    return 0;
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.bodyLarge),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(title), subtitle: Text(value)),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.open_in_new),
      onTap: () {
        _launch(url);
      },
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
