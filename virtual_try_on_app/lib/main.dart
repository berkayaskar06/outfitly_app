import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Adapty SDK using AppConfig
  try {
    await Adapty().activate(
      configuration: AdaptyConfiguration(apiKey: AppConfig.adaptyApiKey),
    );
    await Adapty().setLogLevel(AdaptyLogLevel.verbose);
    debugPrint('✅ Adapty SDK initialized');
  } catch (e) {
    debugPrint('❌ Adapty init failed: $e');
  }
  
  runApp(const ProviderScope(child: VirtualTryOnApp()));
}
