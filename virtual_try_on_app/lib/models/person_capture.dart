import 'package:equatable/equatable.dart';

class PersonCapture extends Equatable {
  const PersonCapture({
    required this.id,
    required this.label,
    required this.imagePath,
    this.thumbnailUrl,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String imagePath;
  final String? thumbnailUrl;
  final DateTime createdAt;

  PersonCapture copyWith({
    String? id,
    String? label,
    String? imagePath,
    String? thumbnailUrl,
    DateTime? createdAt,
  }) {
    return PersonCapture(
      id: id ?? this.id,
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    label,
    imagePath,
    thumbnailUrl,
    createdAt,
  ];
}
