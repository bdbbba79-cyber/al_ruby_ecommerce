import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:al_ruby_ecommerce/firebase_options.dart';
import 'package:al_ruby_ecommerce/core/theme/theme.dart';
import 'package:al_ruby_ecommerce/core/routing/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Try initializing Firebase, log error but allow running (for local UI development)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase initialization failed (e.g. dummy keys)
    // We print the error and continue, allowing UI testing
    debugPrint("Firebase initialization info: $e");
  }

  runApp(
    const ProviderScope(
      child: AlRubyApp(),
    ),
  );
}

class AlRubyApp extends ConsumerWidget {
  const AlRubyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Al Ruby Perfumes',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
