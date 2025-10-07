import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../../models/person_capture.dart';
import '../../../models/product_item.dart';
import '../../../models/try_on_result.dart';

class LibraryState {
  const LibraryState({
    this.persons = const <PersonCapture>[],
    this.products = const <ProductItem>[],
    this.results = const <TryOnResult>[],
  });

  final List<PersonCapture> persons;
  final List<ProductItem> products;
  final List<TryOnResult> results;

  LibraryState copyWith({
    List<PersonCapture>? persons,
    List<ProductItem>? products,
    List<TryOnResult>? results,
  }) {
    return LibraryState(
      persons: persons ?? this.persons,
      products: products ?? this.products,
      results: results ?? this.results,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  LibraryController() : super(const LibraryState());

  final Uuid _uuid = const Uuid();

  void addPersonCapture({
    String? id,
    required String label,
    required String imagePath,
    String? thumbnailUrl,
  }) {
    final person = PersonCapture(
      id: id ?? _uuid.v4(),
      label: label,
      imagePath: imagePath,
      thumbnailUrl: thumbnailUrl,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(persons: <PersonCapture>[person, ...state.persons]);
  }

  void addProduct({
    required String category,
    required String imagePath,
    List<String> styleTags = const <String>[],
  }) {
    final product = ProductItem(
      id: _uuid.v4(),
      category: category,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      styleTags: styleTags,
    );
    state = state.copyWith(products: <ProductItem>[product, ...state.products]);
  }

  void addTryOnResult({
    String? id,
    required String personId,
    required String productId,
    required String imageUrl,
    String? prompt,
  }) {
    final result = TryOnResult(
      id: id ?? _uuid.v4(),
      personId: personId,
      productId: productId,
      imageUrl: imageUrl,
      prompt: prompt,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(results: <TryOnResult>[result, ...state.results]);
  }

  void setResultLike({required String resultId, required bool liked}) {
    state = state.copyWith(
      results: state.results
          .map(
            (result) =>
                result.id == resultId ? result.copyWith(liked: liked) : result,
          )
          .toList(),
    );
  }

  void updateTryOnResult({required String resultId, required TryOnResult updatedResult}) {
    final index = state.results.indexWhere((r) => r.id == resultId);
    if (index >= 0) {
      final updatedResults = List<TryOnResult>.from(state.results);
      updatedResults[index] = updatedResult;
      state = state.copyWith(results: updatedResults);
    }
  }
}

final libraryControllerProvider =
    StateNotifierProvider<LibraryController, LibraryState>((ref) {
      return LibraryController();
    });
