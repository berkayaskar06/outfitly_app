import 'package:equatable/equatable.dart';

class TryOnResult extends Equatable {
  const TryOnResult({
    required this.id,
    required this.personId,
    required this.productId,
    required this.imageUrl,
    this.prompt,
    this.liked,
    this.createdAt,
  });

  final String id;
  final String personId;
  final String productId;
  final String imageUrl;
  final String? prompt;
  final bool? liked;
  final DateTime? createdAt;

  TryOnResult copyWith({
    String? id,
    String? personId,
    String? productId,
    String? imageUrl,
    String? prompt,
    bool? liked,
    DateTime? createdAt,
  }) {
    return TryOnResult(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      productId: productId ?? this.productId,
      imageUrl: imageUrl ?? this.imageUrl,
      prompt: prompt ?? this.prompt,
      liked: liked ?? this.liked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    personId,
    productId,
    imageUrl,
    prompt,
    liked,
    createdAt,
  ];
}
