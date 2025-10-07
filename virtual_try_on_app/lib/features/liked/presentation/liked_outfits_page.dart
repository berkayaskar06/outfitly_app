import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/application/library_controller.dart';

class LikedOutfitsPage extends ConsumerWidget {
  const LikedOutfitsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryControllerProvider);
    final likedResults = library.results.where((r) => r.liked == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liked outfits'),
      ),
      body: SafeArea(
        child: likedResults.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Icon(Icons.favorite_border, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'No liked outfits yet',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Like outfits to see them here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: likedResults.length,
                itemBuilder: (context, index) {
                  final result = likedResults[index];
                  // Product bilgisini bul
                  final product = library.products
                      .where((p) => p.id == result.productId)
                      .firstOrNull;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push('/try-on/result', extra: result),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Stack(
                            children: <Widget>[
                              AspectRatio(
                                aspectRatio: 3 / 4,
                                child: CachedNetworkImage(
                                  imageUrl: result.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .errorContainer,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.pinkAccent,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Outfit ${result.id.substring(0, 8)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(result.createdAt),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (product != null) ...[
                                  const SizedBox(width: 16),
                                  Column(
                                    children: <Widget>[
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: product.imagePath.isNotEmpty &&
                                                File(product.imagePath).existsSync()
                                            ? Image.file(
                                                File(product.imagePath),
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(
                                                _getCategoryIcon(product.category),
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ],
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
    );
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
}



