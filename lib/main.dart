import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart'; // Add this import
import 'core/navigation/route_generator.dart';
import 'core/navigation/route_names.dart';
import 'features/property/data/property_repository.dart';
import 'features/favorites/providers/favorites_provider.dart';
import 'features/property/presentation/providers/property_provider.dart';
import 'features/storage/providers/storage_provider.dart'; // Add this import
import 'features/auth/presentation/providers/auth_provider.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase but don't use auth for now
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Replace print with debugPrint
  debugPrint('Firebase initialized successfully');
  
  // Get SharedPreferences instance for providers
  final sharedPreferences = await SharedPreferences.getInstance();
  
  // Create repositories
  final propertyRepository = PropertyRepository();
  
  runApp(
    MultiProvider(
      providers: [
        // Add ThemeProvider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        // Setup other providers
        ChangeNotifierProvider<PropertyProvider>(
          create: (_) => PropertyProvider(propertyRepository),
        ),
        ChangeNotifierProvider<FavoritesProvider>(
          create: (_) => FavoritesProvider(propertyRepository, sharedPreferences),
        ),
        // Add the StorageProvider
        ChangeNotifierProvider<StorageProvider>(
          create: (_) => StorageProvider(),
        ),
        // Add AuthProvider before other providers that might depend on it
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        // Add other providers here
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current theme from provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      title: 'Real Estate App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode, // Use theme from provider
      debugShowCheckedModeBanner: false,
      initialRoute: RouteNames.splash,
      // Use only one route generation approach - fix the duplicate onGenerateRoute
      onGenerateRoute: RouteGenerator.generateRoute,
      // Handle unknown routes
      onUnknownRoute: (settings) {
        debugPrint('⚠️ App: Unknown route ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
      },
    );
  }
}
