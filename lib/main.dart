import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core imports
import 'core/config/firebase_options.dart';
import 'core/theme/theme_provider.dart'; // Make sure this is imported correctly
import 'core/utils/debug_logger.dart';
import 'core/services/global_auth_service.dart';
import 'core/utils/navigation_logger.dart';
import 'features/auth/domain/providers/auth_provider.dart';
import 'features/property/data/property_repository.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/property/presentation/providers/property_provider.dart';
import 'features/storage/providers/storage_provider.dart';
import 'core/providers/provider_container.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart'; // Import app theme

// Make globalAuthService accessible throughout the app
// FIX: Initialize it immediately with a default value instead of using 'late'
final GlobalAuthService globalAuthService = GlobalAuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DebugLogger.info('🚀 App starting - Flutter binding initialized');
  
  // Set this flag to prevent duplicate initialization
  bool isAppAlreadyInitialized = false;
  
  try {
    // Check if Firebase is already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      DebugLogger.info('✅ Firebase initialized successfully');
    } else {
      DebugLogger.info('✅ Firebase was already initialized, using existing instance');
    }
  } catch (e) {
    DebugLogger.error('❌ Firebase initialization failed', e);
  }

  try {
    if (!isAppAlreadyInitialized) {
      isAppAlreadyInitialized = true;
      DebugLogger.info('🔑 Starting GlobalAuthService initialization');
      await globalAuthService.initialize();
      DebugLogger.info('✅ GlobalAuthService initialized');
      
      // Remove unnecessary null check
      DebugLogger.info('🧩 Initializing AppRouter');
      AppRouter.initializeWithProvider(globalAuthService.authProvider);
      DebugLogger.info('✅ AppRouter initialization complete');
    } else {
      DebugLogger.info('⏩ App already initialized, skipping initialization');
    }
  } catch (e) {
    DebugLogger.error('❌ Error during app initialization', e);
  }
  
  final sharedPreferences = await SharedPreferences.getInstance();
  final propertyRepository = PropertyRepository();
  
  // Initialize global provider container
  final providerContainer = ProviderContainer();
  providerContainer.initialize();
  DebugLogger.provider('Provider container initialized');
  
  // Initialize navigation logger
  NavigationLogger.log(
    NavigationEventType.routeGeneration,
    'App starting',
    data: {'buildMode': kReleaseMode ? 'RELEASE' : 'DEBUG'},
  );

  DebugLogger.info('🏁 Starting app with MultiProvider');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: globalAuthService.authProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<PropertyProvider>(
          create: (_) => PropertyProvider(propertyRepository),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(propertyRepository, sharedPreferences),
        ),
        ChangeNotifierProvider<StorageProvider>(
          create: (_) => StorageProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
  DebugLogger.info('🏁 App started');
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DebugLogger.info('📱 Building MyApp widget');
    try {
      final router = AppRouter.router;
      DebugLogger.info('✅ Got router from AppRouter.router');
      
      return Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Fix: Use isDarkMode from ThemeProvider to select the theme
          final currentTheme = themeProvider.isDarkMode 
              ? AppTheme.darkTheme 
              : AppTheme.lightTheme;
              
          return MaterialApp.router(
            title: 'Real Estate App',
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: currentTheme, // Use the theme directly
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              // Safer implementation without complex theming for now
              return child ?? const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        },
      );
    } catch (e) {
      DebugLogger.error('❌ CRITICAL ERROR in MyApp build', e);
      // Fallback to a basic error screen if routing fails
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white),
                const SizedBox(height: 16),
                const Text('Critical Error', 
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(e.toString(), 
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
