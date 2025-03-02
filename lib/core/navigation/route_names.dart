/// Centralized route names for the application
class RouteNames {
  // Private constructor to prevent instantiation
  RouteNames._();
  
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String resetPassword = '/reset-password';
  static const String landing = '/landing';
  
  // Main app routes
  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  
  // Property routes
  static const String property = '/property/:id';
  static const String propertyDetail = '/property/';
  static const String propertyAdd = '/property/add';
  static const String propertyEdit = '/property/edit/:id';
  static const String propertyUpload = '/property/upload';
  static const String propertyCreate = '/property/create';
  
  // Profile related routes
  static const String editProfile = '/profile/edit';
  static const String myProperties = '/profile/properties';
  static const String history = '/profile/history';
  static const String settings = '/profile/settings';
  static const String support = '/profile/support';
  
  // Admin routes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminProperties = '/admin/properties';
  static const String adminAnalytics = '/admin/analytics';
  
  // Development routes
  static const String diagnostics = '/dev/diagnostics';
}
