import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/route_constants.dart';
import '../presentation/widgets/widgets.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/groups/presentation/screens/screens.dart';
import '../../features/groups/providers/group_provider.dart';
import '../../features/home/presentation/screens/main_scaffold.dart';
import '../../features/timeline/presentation/screens/add_trip_screen.dart';
import '../../features/timeline/presentation/screens/edit_trip_screen.dart';
import '../../features/timeline/presentation/screens/trip_details_screen.dart';
import '../../features/timeline/data/models/trip_model.dart';

/// Router configuration provider with auth state management
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  return GoRouter(
    initialLocation: RouteConstants.splash,
    debugLogDiagnostics: true,
    refreshListenable: authState.maybeWhen(
      data: (user) => GoRouterRefreshStream(Stream.value(user)),
      orElse: () => null,
    ),
    redirect: (context, state) {
      final isAuthRoute = [
        RouteConstants.splash,
        RouteConstants.login,
        RouteConstants.signup,
        RouteConstants.forgotPassword,
      ].contains(state.matchedLocation);
      
      final isEmailVerificationRoute = state.matchedLocation == RouteConstants.emailVerification;
      
      // Get current auth state
      final user = authState.value;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.emailVerified ?? false;
      
      // If on splash, let it handle navigation
      if (state.matchedLocation == RouteConstants.splash) {
        return null;
      }
      
      // If not logged in and not on auth route, redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return RouteConstants.login;
      }
      
      // If logged in but email not verified, redirect to verification
      if (isLoggedIn && !isEmailVerified && !isEmailVerificationRoute && !isAuthRoute) {
        return RouteConstants.emailVerification;
      }
      
      // If logged in with verified email and on auth route, go to home
      if (isLoggedIn && isEmailVerified && (isAuthRoute || isEmailVerificationRoute)) {
        return RouteConstants.home;
      }
      
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: RouteConstants.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth Routes
      GoRoute(
        path: RouteConstants.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteConstants.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RouteConstants.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteConstants.emailVerification,
        name: 'emailVerification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      
      // Main App Routes
      GoRoute(
        path: RouteConstants.home,
        name: 'home',
        builder: (context, state) => const MainScaffold(),
      ),
      
      // Group Routes
      GoRoute(
        path: RouteConstants.groupSelection,
        name: 'groupSelection',
        builder: (context, state) => const GroupSelectionScreen(),
      ),
      GoRoute(
        path: RouteConstants.createGroup,
        name: 'createGroup',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: RouteConstants.joinGroup,
        name: 'joinGroup',
        builder: (context, state) {
          final inviteCode = state.uri.queryParameters['code'];
          return JoinGroupScreen(inviteCode: inviteCode);
        },
      ),
      GoRoute(
        path: '/group-settings/:groupId',
        name: 'groupSettings',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupSettingsScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/group-settings/:groupId/edit',
        name: 'editGroupSettings',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return EditGroupSettingsScreen(groupId: groupId);
        },
      ),
      
      // Trip Routes
      GoRoute(
        path: '/add-trip',
        name: 'addTrip',
        builder: (context, state) {
          final groupId = state.uri.queryParameters['groupId']!;
          return AddTripScreen(groupId: groupId);
        },
      ),
      GoRoute(
        path: '/edit-trip',
        name: 'editTrip',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final groupId = extra['groupId'] as String;
          final trip = extra['trip'] as TripModel;
          return EditTripScreen(groupId: groupId, trip: trip);
        },
      ),
      GoRoute(
        path: '/trip/:tripId',
        name: 'tripDetails',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final groupId = extra?['groupId'] as String? ?? state.uri.queryParameters['groupId']!;
          return TripDetailsScreen(groupId: groupId, tripId: tripId);
        },
      ),
    ],
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
});

/// Helper class to refresh router when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Placeholder screens for unimplemented features
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userGroupsAsync = ref.watch(userGroupsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secret Holiday Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.flight_takeoff,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome!',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start planning your secret holiday adventures',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),
                
                // Group count indicator
                userGroupsAsync.when(
                  data: (groups) => groups.isEmpty 
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.group_add,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No Groups Yet',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create or join a group to get started',
                                style: theme.textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.groups,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Your Groups',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${groups.length} ${groups.length == 1 ? 'group' : 'groups'}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                
                const SizedBox(height: 24),
                
                PrimaryButton(
                  text: 'My Groups',
                  onPressed: () => context.go(RouteConstants.groupSelection),
                  icon: Icons.group,
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  text: 'Create Group',
                  onPressed: () => context.go(RouteConstants.createGroup),
                  icon: Icons.add,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  text: 'Join Group',
                  onPressed: () => context.go(RouteConstants.joinGroup),
                  icon: Icons.link,
                ),
                const SizedBox(height: 40),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final Exception? error;
  
  const ErrorScreen({super.key, this.error});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('An error occurred: ${error?.toString() ?? "Unknown error"}'),
      ),
    );
  }
}
