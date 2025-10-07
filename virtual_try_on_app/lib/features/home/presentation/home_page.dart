import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/application/library_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your wardrobe'),
        actions: <Widget>[
          IconButton(
            onPressed: () => context.push('/liked'),
            icon: const Icon(Icons.favorite_outline),
          ),
          IconButton(
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/person-select'),
        icon: const Icon(Icons.add_photo_alternate),
        label: const Text('New try-on'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: <Widget>[
            _Section(
              title: 'Uploaded persons',
              trailing: TextButton(
                onPressed: () => context.push('/person-select'),
                child: const Text('Add new'),
              ),
              child: library.persons.isEmpty
                  ? const _EmptyPlaceholder(message: 'Add your photo to begin.')
                  : SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: library.persons.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final person = library.persons[index];
                          return GestureDetector(
                            onTap: () =>
                                context.push('/upload', extra: person.id),
                            child: Column(
                              children: <Widget>[
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  backgroundImage: person.imagePath.isNotEmpty
                                      ? FileImage(File(person.imagePath))
                                      : null,
                                  child: person.imagePath.isEmpty
                                      ? Text(
                                          person.label.characters.first
                                              .toUpperCase(),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium,
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    person.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Recent products',
              child: library.products.isEmpty
                  ? const _EmptyPlaceholder(
                      message: 'Add a garment to test it on.',
                    )
                  : SizedBox(
                      height: 220,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: library.products.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final product = library.products[index];
                          final image = product.imagePath;
                          final imageWidget = image.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: image,
                                  fit: BoxFit.cover,
                                )
                              : (image.isNotEmpty && File(image).existsSync())
                                  ? Image.file(
                                      File(image),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _getCategoryIcon(product.category),
                                        size: 48,
                                      ),
                                    );
                          return SizedBox(
                            width: 160,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    height: 140,
                                    width: double.infinity,
                                    child: imageWidget,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: <Widget>[
                                        Icon(
                                          _getCategoryIcon(product.category),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            product.category,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            _Section(
              title: 'Latest outfits',
              child: library.results.isEmpty
                  ? const _EmptyPlaceholder(
                      message: 'Generate try-ons to see them here.',
                    )
                  : Column(
                      children: library.results
                          .map(
                            (result) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => context.push(
                                  '/try-on/result',
                                  extra: result,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    AspectRatio(
                                      aspectRatio: 3 / 4,
                                      child: CachedNetworkImage(
                                        imageUrl: result.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            Container(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.errorContainer,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                'Try-on ${result.id.substring(0, 6)}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                              Text(
                                                _formatDate(result.createdAt),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          Icon(
                                            result.liked == true
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: result.liked == true
                                                ? Colors.pinkAccent
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

String _formatDate(DateTime? timestamp) {
  if (timestamp == null) {
    return '';
  }
  final date = timestamp.toLocal();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'dresses':
      return Icons.checkroom;
    case 'tops':
      return Icons.dry_cleaning;
    case 'outerwear':
      return Icons.ac_unit;
    case 'bottoms':
      return Icons.shopping_bag;
    case 'shoes':
      return Icons.ice_skating;
    case 'accessories':
      return Icons.watch;
    default:
      return Icons.checkroom;
  }
}
