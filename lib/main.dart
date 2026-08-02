import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:al_ruby_ecommerce/firebase_options.dart';
import 'package:al_ruby_ecommerce/core/theme/theme.dart';
import 'package:al_ruby_ecommerce/core/routing/router.dart';
import 'package:al_ruby_ecommerce/presentation/widgets/offline_wrapper.dart';
import 'package:al_ruby_ecommerce/presentation/providers/providers.dart';
import 'package:al_ruby_ecommerce/data/models/user_model.dart';
import 'package:al_ruby_ecommerce/core/routing/url_strategy.dart'
    if (dart.library.html) 'package:al_ruby_ecommerce/core/routing/url_strategy_web.dart';

void main() async {
  configureUrlStrategy();
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

    // Automatically sync the user authentication details into the StateProvider
    ref.listen<AsyncValue<UserModel?>>(userDetailsProvider, (previous, next) {
      if (next is AsyncData<UserModel?>) {
        ref.read(currentUserDetailsProvider.notifier).state = next.value;
      }
    });

    return MaterialApp.router(
      title: 'Al Ruby Perfumes',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return OfflineWrapper(child: child ?? const SizedBox());
      },
    );
  }
}
