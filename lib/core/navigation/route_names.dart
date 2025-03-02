/// Centralized route names for the application
/// 
/// This class provides static constants for all named routes in the application
/// to prevent hardcoding strings throughout the codebase.
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();
  
  // Auth routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  
  // Main app routes
  static const String initial = '/'; // Add this for initial route
  static const String home = '/';
  static const String search = '/search';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String favorites = '/favorites'; // Add this for favorites
  
  // Property routes
  static const String propertyDetail = '/property/:id';
  static const String propertyList = '/properties';
  static const String propertyMap = '/properties/map';
  static const String propertyCreate = '/property/create';
  static const String propertyEdit = '/property/:id/edit';
  static const String propertyUpload = '/property/upload';
  
  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminProperties = '/admin/properties';
  static const String adminUsers = '/admin/users';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
  static const String adminUpload = '/admin/upload';
}
