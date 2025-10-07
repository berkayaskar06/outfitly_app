import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/try_on_result.dart';
import '../application/try_on_controller.dart';

class TryOnResultPage extends ConsumerWidget {
  const TryOnResultPage({super.key, this.result});

  final TryOnResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TryOnResult? viewResult =
        result ?? ModalRoute.of(context)?.settings.arguments as TryOnResult?;
    final state = ref.watch(tryOnControllerProvider);
    final activeResult = viewResult ?? state.result;
    if (activeResult == null) {
      return const Scaffold(
        body: Center(child: Text('No try-on result available.')),
      );
    }
    final liked = activeResult.liked ?? false;
    final imageUrl = activeResult.imageUrl;
    final hasImage = imageUrl.isNotEmpty;
    final isLoading = state.isLoading;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your new outfit'),
        actions: <Widget>[
          IconButton(
            onPressed: () => _toggleLike(ref, activeResult, !liked),
            icon: Icon(liked ? Icons.favorite : Icons.favorite_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: hasImage
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  _ImageError(url: url),
                            )
                          : _ImagePlaceholder(isLoading: isLoading),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        _toggleLike(ref, activeResult, true);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saved to likes.')),
                        );
                      },
                      icon: const Icon(Icons.favorite),
                      label: const Text('Like'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _toggleLike(ref, activeResult, false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Marked as dislike.')),
                        );
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Dislike'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Ana sayfaya dön (tüm stack'i temizle)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Back to home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleLike(WidgetRef ref, TryOnResult result, bool like) {
    ref.read(tryOnControllerProvider.notifier).setActiveResultLike(like);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isLoading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text('AI çıktısı hazırlanıyor...'),
          ] else ...[
            const Icon(Icons.image_outlined, size: 64),
            const SizedBox(height: 12),
            const Text('Görsel bekleniyor...'),
          ],
        ],
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      child: Text(
        'Görsel yüklenemedi.\n$url',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
