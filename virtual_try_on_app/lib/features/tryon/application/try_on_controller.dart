import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../models/try_on_result.dart';
import '../../../services/api_service.dart';
import '../../shared/application/library_controller.dart';

class TryOnState {
  const TryOnState({
    this.isLoading = false,
    this.error,
    this.personId,
    this.productId,
    this.prompt,
    this.result,
  });

  final bool isLoading;
  final String? error;
  final String? personId;
  final String? productId;
  final String? prompt;
  final TryOnResult? result;

  TryOnState copyWith({
    bool? isLoading,
    String? error,
    String? personId,
    String? productId,
    String? prompt,
    TryOnResult? result,
  }) {
    return TryOnState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      personId: personId ?? this.personId,
      productId: productId ?? this.productId,
      prompt: prompt ?? this.prompt,
      result: result ?? this.result,
    );
  }
}

class TryOnController extends StateNotifier<TryOnState> {
  TryOnController(this._ref) : super(const TryOnState());

  final Ref _ref;

  ApiService get _api => _ref.read(apiServiceProvider);
  LibraryController get _library =>
      _ref.read(libraryControllerProvider.notifier);

  Future<void> uploadPerson(File image, {required String label}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final personId = await _api.uploadPersonImage(image);
      _library.addPersonCapture(
        id: personId,
        label: label,
        imagePath: image.path,
      );
      state = state.copyWith(isLoading: false, personId: personId);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> uploadProduct(
    File image, {
    required String category,
    List<String> styleTags = const <String>[],
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final productId = await _api.uploadProductImage(
        image: image,
        category: category,
      );
      _library.addProduct(
        category: category,
        imagePath: image.path,
        styleTags: styleTags,
      );
      state = state.copyWith(isLoading: false, productId: productId);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<TryOnResult?> generateTryOn({required String prompt}) async {
    final personId = state.personId;
    final productId = state.productId;
    if (personId == null || productId == null) {
      state = state.copyWith(error: 'Upload person and product images first.');
      return null;
    }
    state = state.copyWith(isLoading: true, error: null, prompt: prompt);
    try {
      var result = await _api.requestTryOn(
        personId: personId,
        productId: productId,
        prompt: prompt,
      );
      // İlk result'u state'e kaydet (image URL boş olsa bile)
      state = state.copyWith(isLoading: true, result: result);
      
      // Eğer image URL boşsa, polling yap ve her güncellemeyi state'e yansıt
      if (result.imageUrl.isEmpty) {
        debugPrint('🔄 Starting polling for try-on result: ${result.id}');
        for (var attempt = 0; attempt < 15; attempt++) {
          await Future<void>.delayed(const Duration(seconds: 2));
          debugPrint('🔄 Polling attempt ${attempt + 1}/15...');
          final refreshed = await _api.getTryOnResult(result.id);
          // Her polling sonucunu state'e kaydet
          state = state.copyWith(result: refreshed);
          result = refreshed;
          
          if (refreshed.imageUrl.isNotEmpty) {
            debugPrint('✅ Image URL received! ${refreshed.imageUrl.substring(0, 60)}...');
            break;
          } else {
            debugPrint('⏳ Still waiting for image...');
          }
        }
        
        if (result.imageUrl.isEmpty) {
          debugPrint('❌ Polling completed but no image URL received');
        }
      }
      
      // Image URL geldiyse library'ye ekle
      if (result.imageUrl.isNotEmpty) {
        _library.addTryOnResult(
          id: result.id,
          personId: personId,
          productId: productId,
          imageUrl: result.imageUrl,
          prompt: prompt,
        );
      }
      
      state = state.copyWith(isLoading: false, result: result);
      // Ücretsiz deneme sayacını artır (Paywall görünümü için)
      try {
        final prefs = await SharedPreferences.getInstance();
        final used = prefs.getInt('used_try_on_count') ?? 0;
        await prefs.setInt('used_try_on_count', used + 1);
      } catch (_) {}
      return result;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
      return null;
    }
  }

  void resetSession() {
    state = const TryOnState();
  }

  void setActiveResultLike(bool liked) {
    final active = state.result;
    if (active == null) {
      return;
    }
    _library.setResultLike(resultId: active.id, liked: liked);
    state = state.copyWith(result: active.copyWith(liked: liked));
  }
}

final tryOnControllerProvider =
    StateNotifierProvider<TryOnController, TryOnState>((ref) {
      return TryOnController(ref);
    });
