import 'package:flutter/material.dart';
import '../../features/property/presentation/screens/property_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../auth/wrappers/auth_wrapper.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'route_names.dart';
import '/features/admin/presentation/screens/property_upload_screen.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    debugPrint('⚙️ RouteGenerator: Generating route for ${settings.name}');
    
    // Get arguments passed to the route
    final args = settings.arguments;

    switch (settings.name) {
      case RouteNames.home:
        // Use the AuthWrapper which is modified to go straight to HomeScreen
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      
      // Remove the duplicate '/' case since it's covered by RouteNames.home above
      
      case RouteNames.search:
        final query = args as String?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: query),
        );
      
      case RouteNames.propertyDetail:
        final propertyId = args as String;
        return MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(id: propertyId),
        );
      
      case RouteNames.favorites:
        return MaterialPageRoute(
          builder: (_) => const FavoritesScreen(),
        );
      
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      case RouteNames.propertyUpload:
        debugPrint('🚀 Generating route for PropertyUploadScreen');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PropertyUploadScreen(), // Remove isAdminMode parameter
        );

      case RouteNames.login:
        // Pass any arguments to the login screen
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      
      default:
        // If no matching route is found, return an error page
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
