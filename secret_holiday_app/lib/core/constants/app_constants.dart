/// Application-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Secret Holiday';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String groupsCollection = 'groups';
  static const String tripsCollection = 'trips';
  static const String chatCollection = 'chat';
  static const String planningCollection = 'planning';
  
  // Storage Paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String tripMediaPath = 'trip_media';
  static const String chatMediaPath = 'chat_media';
  
  // Preferences Keys
  static const String themeKey = 'theme_mode';
  static const String currentGroupKey = 'current_group_id';
  static const String languageKey = 'language_code';
  
  // Limits
  static const int maxGroupMembers = 20;
  static const int maxTripPhotos = 100;
  static const int maxVideoSizeMB = 50;
  static const int chatHistoryLimit = 50;
  
  // Budget Categories
  static const int lowBudget = 500;
  static const int midBudget = 1500;
  static const int highBudget = 3000;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 600);
  
  // API Keys (to be configured)
  static const String openAIKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_KEY');
}
