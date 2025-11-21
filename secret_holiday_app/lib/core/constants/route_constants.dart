/// Route name constants for navigation
class RouteConstants {
  // Auth Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  
  // Group Routes
  static const String groupSelection = '/groups';
  static const String createGroup = '/create-group';
  static const String joinGroup = '/join-group';
  static const String groupSettings = '/group-settings';
  
  // Main Routes
  static const String home = '/home';
  static const String timeline = '/timeline';
  static const String map = '/map';
  static const String chat = '/chat';
  static const String planning = '/planning';
  static const String profile = '/profile';
  
  // Trip Routes
  static const String tripDetail = '/trip/:tripId';
  static const String addTrip = '/add-trip';
  static const String editTrip = '/edit-trip/:tripId';
  
  // Profile Routes
  static const String editProfile = '/edit-profile';
  static const String travelInfo = '/travel-info';
  
  // Organizer Routes
  static const String selectOrganizer = '/select-organizer';
  static const String aiPlanning = '/ai-planning';
}
