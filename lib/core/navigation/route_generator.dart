import 'package:flutter/material.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/property/presentation/screens/property_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/favorites/screens/favorites_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../auth/wrappers/auth_wrapper.dart'; // Import the auth wrapper
import 'route_names.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
      case '/':
        // Use the AuthWrapper which is modified to go straight to HomeScreen
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
      
      case RouteNames.search:
        final query = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: query),
        );
      
      case RouteNames.propertyDetail:
        final propertyId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => PropertyDetailScreen(id: propertyId),
        );
      
      case RouteNames.favorites:
        return MaterialPageRoute(
          builder: (_) => const FavoritesScreen(),
        );
      
      case RouteNames.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      default:
        // Default also goes to the AuthWrapper
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
    }
  }
}
