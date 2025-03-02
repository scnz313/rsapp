import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/property/presentation/screens/property_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../auth/wrappers/auth_wrapper.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/admin/presentation/screens/property_upload_screen.dart';
import '../../features/auth/presentation/screens/landing_screen.dart';
import '../../core/utils/debug_logger.dart';
import '../../core/services/global_auth_service.dart';  // Add missing import
import 'route_names.dart';
import '../../features/dev/screens/navigation_diagnostic_screen.dart';
import '../../core/utils/navigation_logger.dart';

class RouteGenerator {
  // Add this method to fix the reference in main.dart
  static Route<dynamic> createRoute(RouteSettings settings, BuildContext context) {
    DebugLogger.route('Creating route with context for: ${settings.name}');
    return generateRoute(settings);
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    NavigationLogger.log(NavigationEventType.routeGeneration, 'Generating route for: ${settings.name}');
    
    // Create a map to track all the routes we're trying to handle
    final Map<String, String?> routesMap = {
      'requested': settings.name,
      'home': RouteNames.home,
      'login': RouteNames.login,
      'register': RouteNames.register,
      'resetPassword': RouteNames.resetPassword,
      'propertyDetail': RouteNames.propertyDetail,
      // Add more routes for debugging
    };
    
    NavigationLogger.log(
      NavigationEventType.routeChange,
      'Route Constants Check',
      data: routesMap,
    ); // Fixed: Removed extra closing parenthesis

    switch (settings.name) {
      case RouteNames.home:
      case '/':
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to HomeScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            NavigationLogger.log(NavigationEventType.routeChange, 'Building HomeScreen');
            return const HomeScreen();
          },
        );
      
      case RouteNames.search:
        final query = settings.arguments as String?;
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to SearchScreen', data: query);
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => SearchScreen(initialQuery: query),
        );
      
      case RouteNames.propertyDetail:
        final propertyId = settings.arguments as String;
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to PropertyDetailScreen', data: propertyId);
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => PropertyDetailScreen(propertyId: propertyId),
        );
      
      case RouteNames.favorites:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to FavoritesScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const FavoritesScreen(),
        );
      
      case RouteNames.profile:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to ProfileScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const ProfileScreen(),
        );
      
      case RouteNames.propertyUpload:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to PropertyUploadScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const PropertyUploadScreen(),
        );

      case RouteNames.login:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to LoginScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            // Check if provider is available in the LoginScreen
            try {
              final GlobalAuthService authService = GlobalAuthService();
              NavigationLogger.log(
                NavigationEventType.providerAccess,
                'Using GlobalAuthService in LoginScreen route',
                data: 'isAuthenticated: ${authService.isAuthenticated}',
              );
            } catch (e) {
              NavigationLogger.log(
                NavigationEventType.providerError,
                'Error accessing GlobalAuthService in LoginScreen route',
                data: e,
              );
            }
            return const LoginScreen();
          },
        );

      case RouteNames.register:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to RegisterScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            try {
              // Check if auth provider is available
              final globalAuthService = GlobalAuthService();
              NavigationLogger.log(
                NavigationEventType.providerAccess,
                'Using GlobalAuthService in RegisterScreen route',
                data: 'isAuthenticated: ${globalAuthService.isAuthenticated}',
              );
            } catch (e) {
              NavigationLogger.log(
                NavigationEventType.providerError,
                'Error accessing GlobalAuthService in RegisterScreen route',
                data: e,
              );
            }
            return const RegisterScreen();
          },
        );

      case RouteNames.landing:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to LandingScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const LandingScreen(),
        );
        
      case RouteNames.diagnostics:
        NavigationLogger.log(NavigationEventType.routeChange, 'Routing to Navigation Diagnostics');
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const NavigationDiagnosticScreen(),
        );
      
      default:
        NavigationLogger.log(
          NavigationEventType.error, 
          'No route found for ${settings.name}',
          data: settings.arguments,
        );
        
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            return Scaffold(
              appBar: AppBar(title: const Text('Route Not Found')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Page not found!',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    Text('Attempted route: ${settings.name}'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteNames.home,
                          (route) => false,
                        );
                      }, // Fixed: Added missing closing parenthesis
                      child: const Text('Go to Home'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  static Route<dynamic> _errorRoute(String routeName) {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Error: $routeName not found'),
          ),
          body: Center(
            child: Text('Route $routeName not found'),
          ),
        );
      },
    );
  }
}
