import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/debug_logger.dart';
import 'core/services/global_auth_service.dart';
import 'core/utils/navigation_logger.dart';
import 'features/auth/domain/providers/auth_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/property/data/property_repository.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/property/presentation/providers/property_provider.dart';
import 'features/storage/providers/storage_provider.dart';
import 'core/navigation/route_generator.dart';
import 'core/providers/provider_container.dart';
import 'core/navigation/route_observer.dart';

// Make globalAuthService accessible throughout the app
// FIX: Initialize it immediately with a default value instead of using 'late'
final GlobalAuthService globalAuthService = GlobalAuthService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  DebugLogger.info('Firebase initialized successfully');
  
  // Initialize global auth service
  // FIX: Use the already initialized instance instead of creating a new one
  await globalAuthService.initialize();
  DebugLogger.provider('Global auth service initialized');
  
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
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        // Use the auth provider from the global service
        ChangeNotifierProvider<AuthProvider>.value(
          value: globalAuthService.authProvider,
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
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    NavigationLogger.log(
      NavigationEventType.routeGeneration,
      'Building MyApp',
    );
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: themeProvider.isDarkMode 
                ? Brightness.light 
                : Brightness.dark,
            systemNavigationBarColor: themeProvider.isDarkMode
                ? Colors.black
                : Colors.white,
            systemNavigationBarIconBrightness: themeProvider.isDarkMode
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        
        return MaterialApp(
          title: 'Real Estate App',
          navigatorObservers: [AppRouteObserver()], 
          theme: themeProvider.themeData,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false,
          // Use a builder to ensure providers are available during navigation
          builder: (context, child) {
            // Add providers that need to persist across navigation
            return MultiProvider(
              providers: [
                // Re-provide auth provider to ensure it's available everywhere
                ChangeNotifierProvider<AuthProvider>.value(
                  value: globalAuthService.authProvider,
                ),
                // Add any other providers that need to be accessible during/after navigation
              ],
              child: child!,
            );
          },
          // Rest of your MaterialApp configuration...
          home: Builder(
            builder: (context) {
              NavigationLogger.log(
                NavigationEventType.routeGeneration,
                'Building Initial Screen (SplashScreen)'
              );
              return const SplashScreen();
            }
          ),
          onGenerateRoute: (RouteSettings settings) {
            DebugLogger.route('Generating route for ${settings.name}');
            // Skip handling the initial route (/) since we're using home:
            if (settings.name == '/') {
              NavigationLogger.log(
                NavigationEventType.routeOverride,
                'Skipping initial route "/"',
              );
              return null;
            }
            // For all other routes, use the route generator
            return RouteGenerator.createRoute(settings, context);
          },
        );
      },
    );
  }
}
