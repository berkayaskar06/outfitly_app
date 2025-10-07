import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/try_on_result.dart';
import '../utils/constants.dart';

class ApiService {
  ApiService(this._client) {
    _client.options = BaseOptions(
      baseUrl: AppConfig.backendBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      // Keep default validateStatus; we log all responses below
    );

    // Lightweight request/response logging for debugging connectivity
    _client.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        debugPrint('[API] -> ${options.method} ${_client.options.baseUrl}${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('[API] <- ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        final req = e.requestOptions;
        debugPrint('[API] !! ${req.method} ${req.uri} failed: ${e.response?.statusCode} ${e.message}');
        return handler.next(e);
      },
    ));
  }

  final Dio _client;

  Future<Map<String, dynamic>> login(String email, String name) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/api/auth/login-or-register',
        data: <String, dynamic>{'email': email, 'name': name},
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      debugPrint('Login failed: ${error.message}');
      rethrow;
    }
  }

  Future<String> uploadPersonImage(File image) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.uri.pathSegments.last,
      ),
    });
    final response = await _client.post<Map<String, dynamic>>(
      '/api/persons',
      data: formData,
    );
    return response.data?['person_id'] as String;
  }

  Future<String> uploadProductImage({
    required File image,
    required String category,
  }) async {
    final formData = FormData.fromMap(<String, dynamic>{
      'image': await MultipartFile.fromFile(
        image.path,
        filename: image.uri.pathSegments.last,
      ),
      'category': category,
    });
    final response = await _client.post<Map<String, dynamic>>(
      '/api/products',
      data: formData,
    );
    return response.data?['product_id'] as String;
  }

  Future<TryOnResult> requestTryOn({
    required String personId,
    required String productId,
    required String prompt,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/api/try-on',
      data: <String, dynamic>{
        'person_id': personId,
        'product_id': productId,
        'prompt': prompt,
      },
    );
    final data = response.data ?? <String, dynamic>{};
    final imageUrl = _extractImageUrl(data) ?? '';
    return TryOnResult(
      id: data['try_on_id'] as String,
      personId: personId,
      productId: productId,
      imageUrl: imageUrl,
      prompt: prompt,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<TryOnResult> getTryOnResult(String tryOnId) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/try-on/$tryOnId',
    );
    final data = response.data ?? <String, dynamic>{};
    final imageUrl = _extractImageUrl(data) ?? '';
    
    debugPrint('🔍 [TryOn $tryOnId] API Response:');
    debugPrint('  Status: ${data['status']}');
    debugPrint('  Image URL: ${imageUrl.isEmpty ? "EMPTY" : imageUrl.substring(0, imageUrl.length > 60 ? 60 : imageUrl.length)}...');
    debugPrint('  Raw data keys: ${data.keys.toList()}');
    
    return TryOnResult(
      id: data['try_on_id'] as String,
      personId: data['person_id'] as String,
      productId: data['product_id'] as String,
      imageUrl: imageUrl,
      prompt: data['prompt'] as String?,
      liked: data['liked'] as bool?,
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<String> fetchPrompt(String category) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/api/prompts',
      queryParameters: <String, dynamic>{'category': category},
    );
    final data = response.data ?? <String, dynamic>{};
    return (data['prompt'] ?? '') as String;
  }

  String? _extractImageUrl(Map<String, dynamic> data) {
    debugPrint('🔎 Extracting image URL from data...');
    
    final String? directUrl = data['image_url'] as String?;
    if (directUrl != null && directUrl.isNotEmpty) {
      debugPrint('  ✅ Found direct image_url: ${directUrl.substring(0, directUrl.length > 60 ? 60 : directUrl.length)}...');
      return directUrl;
    }
    
    debugPrint('  ❌ No direct image_url found');
    
    final images = data['images'];
    if (images is List && images.isNotEmpty) {
      debugPrint('  🔍 Checking images array (${images.length} items)...');
      final first = images.first;
      if (first is Map<String, dynamic>) {
        final url = first['url'];
        if (url is String && url.isNotEmpty) {
          debugPrint('  ✅ Found URL in images[0]: ${url.substring(0, url.length > 60 ? 60 : url.length)}...');
          return url;
        }
      }
    }
    
    final resultUrl = data['result_url'];
    if (resultUrl is String && resultUrl.isNotEmpty) {
      debugPrint('  ✅ Found result_url: ${resultUrl.substring(0, resultUrl.length > 60 ? 60 : resultUrl.length)}...');
      return resultUrl;
    }
    
    debugPrint('  ❌ No image URL found in response');
    return null;
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(Dio());
});
