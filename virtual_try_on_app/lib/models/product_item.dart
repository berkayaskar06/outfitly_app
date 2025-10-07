import 'package:equatable/equatable.dart';

class ProductItem extends Equatable {
  const ProductItem({
    required this.id,
    required this.category,
    required this.imagePath,
    this.thumbnailUrl,
    this.styleTags = const <String>[],
    required this.createdAt,
  });

  final String id;
  final String category;
  final String imagePath;
  final String? thumbnailUrl;
  final List<String> styleTags;
  final DateTime createdAt;

  ProductItem copyWith({
    String? id,
    String? category,
    String? imagePath,
    String? thumbnailUrl,
    List<String>? styleTags,
    DateTime? createdAt,
  }) {
    return ProductItem(
      id: id ?? this.id,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      styleTags: styleTags ?? this.styleTags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    category,
    imagePath,
    thumbnailUrl,
    styleTags,
    createdAt,
  ];
}
