import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/firebase_options.dart';
import 'core/data/destination_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run app immediately with a loading screen, initialize Firebase in parallel
  runApp(ProviderScope(child: FirebaseInitWrapper()));
}

/// Wrapper that shows loading while Firebase initializes
/// This prevents the "app not responding" by showing UI immediately
class FirebaseInitWrapper extends StatefulWidget {
  const FirebaseInitWrapper({super.key});

  @override
  State<FirebaseInitWrapper> createState() => _FirebaseInitWrapperState();
}

class _FirebaseInitWrapperState extends State<FirebaseInitWrapper> {
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase and destination data in parallel
      await Future.wait([
        Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        DestinationRepository.instance.initialize(),
      ]);
      if (kDebugMode) {
        AppLogger.info('Firebase and destinations initialized successfully');
      }
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize app', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error state
    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to initialize app'),
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading while initializing
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Starting...'),
              ],
            ),
          ),
        ),
      );
    }

    // Firebase is ready, show the real app
    return const MyApp();
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Secret Holiday',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
