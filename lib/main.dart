import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// Core imports
import 'core/config/firebase_options.dart';
import 'core/theme/theme_provider.dart';
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
import 'core/theme/app_theme.dart';

// Make globalAuthService accessible throughout the app
final GlobalAuthService globalAuthService = GlobalAuthService();

// Flag to track if App Check was successfully initialized
bool _isAppCheckInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DebugLogger.info('🚀 App starting - Flutter binding initialized');

  // Guard flag to prevent duplicate initializations
  bool isAppAlreadyInitialized = false;

  try {
    // IMPORTANT: Only initialize Firebase once by checking apps list
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      DebugLogger.info('✅ Firebase initialized successfully');
    } else {
      // If Firebase is already initialized, use the existing instance
      DebugLogger.info(
          '✅ Firebase was already initialized, using existing instance');
    }

    // Initialize App Check with proper error handling
    // Do this before auth initialization to ensure tokens are available
    try {
      await _initializeAppCheck();
      _isAppCheckInitialized = true;
    } catch (e) {
      // Don't fail the app just because App Check failed
      _isAppCheckInitialized = false;
      DebugLogger.error(
          '❌ Firebase App Check initialization error - continuing anyway', e);
    }

    // Let the system settle a bit after App Check initialization
    await Future.delayed(const Duration(milliseconds: 500));

    // Initialize global auth service if not already done
    if (!isAppAlreadyInitialized) {
      isAppAlreadyInitialized = true;

      try {
        DebugLogger.info('🔑 Starting GlobalAuthService initialization');
        await globalAuthService.initialize();
        DebugLogger.info('✅ GlobalAuthService initialized');
      } catch (e) {
        DebugLogger.error('❌ Error initializing GlobalAuthService', e);
        // Create emergency auth provider to prevent null errors
        globalAuthService.createEmergencyAuthProvider();
      }
    }
  } catch (e) {
    DebugLogger.error('❌ Error during app initialization', e);
    // Create emergency auth provider to ensure app doesn't crash
    globalAuthService.createEmergencyAuthProvider();
  }

  // Initialize shared preferences and repositories
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

  // Build and run app
  DebugLogger.info('🏁 Starting app with MultiProvider');

  // Run the app with proper error handling
  runApp(
    MultiProvider(
      providers: [
        // Make sure to handle null auth provider case
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
          create: (_) =>
              FavoritesProvider(propertyRepository, sharedPreferences),
        ),
        ChangeNotifierProvider<StorageProvider>(
          create: (_) => StorageProvider(),
        ),
      ],
      child: const AppWithErrorBoundary(),
    ),
  );

  DebugLogger.info('🏁 App started');
}

// App Check initialization with proper retry and error handling
Future<void> _initializeAppCheck() async {
  if (kDebugMode) {
    DebugLogger.info(
        'ℹ️ INFO: Using debug App Check provider in development mode');
  }

  // In debug mode, bypass App Check initialization entirely if previously failed
  if (kDebugMode && _isAppCheckInitialized == false) {
    // Activate with debug provider but don't actively fetch tokens
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
      webProvider: ReCaptchaV3Provider('dummy-key'),
    );
    return;
  }

  int retryCount = 0;
  const maxRetries = 2; // Reduced to prevent too many attempts error
  const retryDelay = Duration(milliseconds: 1500);

  while (retryCount < maxRetries) {
    try {
      // For debug builds, always use debug provider
      // For release builds, use platform-specific secure providers
      await FirebaseAppCheck.instance.activate(
        // Debug provider for Android during development
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,

        // Debug provider for iOS during development
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,

        // Debug provider for web during development (with a dummy key)
        webProvider: kDebugMode ? ReCaptchaV3Provider('dummy-key') : null,
      );

      // Only try to get a token in release mode or if we haven't had previous failures
      // This helps avoid the "Too many attempts" error
      if (!kDebugMode) {
        await FirebaseAppCheck.instance.getToken(false); // Don't force refresh
      }

      DebugLogger.info('✅ Firebase App Check initialized successfully');
      return;
    } catch (e) {
      DebugLogger.error(
          '❌ Firebase App Check initialization error (attempt ${retryCount + 1})',
          e);

      if (retryCount >= maxRetries - 1) {
        // On final retry, just continue without full App Check in debug mode
        if (kDebugMode) {
          DebugLogger.info(
              '⚠️ Continuing without full App Check in debug mode');
          return;
        }
        rethrow;
      }

      await Future.delayed(retryDelay);
      retryCount++;
    }
  }
}

// Top-level error boundary component
class AppWithErrorBoundary extends StatefulWidget {
  const AppWithErrorBoundary({Key? key}) : super(key: key);

  @override
  State<AppWithErrorBoundary> createState() => _AppWithErrorBoundaryState();
}

class _AppWithErrorBoundaryState extends State<AppWithErrorBoundary> {
  // Track initialization state
  bool _isRouterInitialized = false;
  String? _initError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize the router with the auth provider from context
    if (!_isRouterInitialized) {
      try {
        // This is key - properly initialize the AppRouter with the auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        AppRouter.initializeWithProvider(authProvider);
        setState(() {
          _isRouterInitialized = true;
        });
      } catch (e) {
        DebugLogger.error('Failed to initialize router', e);
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      // Show error screen if router initialization failed
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.red.shade100,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(color: Colors.red, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Restart app state to attempt recovery
                    setState(() {
                      _initError = null;
                      _isRouterInitialized = false;
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show loading screen until router is initialized
    if (!_isRouterInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing application...'),
              ],
            ),
          ),
        ),
      );
    }

    // Once router is initialized, show the actual app
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DebugLogger.info('📱 Building MyApp widget');
    try {
      // Router should be initialized by now
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
              return child ??
                  const Scaffold(
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
                const Text(
                  'Critical Error',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to root to attempt recovery
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  child: const Text('Go to Home Screen'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
