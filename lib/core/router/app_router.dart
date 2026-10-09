import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/screens/chat_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/violation/screens/violation_screen.dart';
import '../di/providers.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const emergency = '/emergency';
  static const violation = '/violation';
  static const chat = '/chat';
  static const profile = '/profile';
}

/// No saved profile → /onboarding (first launch). Otherwise onboarding is
/// skipped. Screens that save a profile must `ref.invalidate(profileProvider)`.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    redirect: (context, state) async {
      final bool hasProfile;
      try {
        hasProfile = await ref.read(profileProvider.future) != null;
      } catch (_) {
        return null; // Storage error: don't bounce the user into onboarding.
      }
      final atOnboarding = state.matchedLocation == Routes.onboarding;
      if (!hasProfile && !atOnboarding) return Routes.onboarding;
      if (hasProfile && atOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.emergency,
        builder: (_, _) => const EmergencyScreen(),
      ),
      GoRoute(
        path: Routes.violation,
        builder: (_, _) => const ViolationScreen(),
      ),
      GoRoute(path: Routes.chat, builder: (_, _) => const ChatScreen()),
      GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
    ],
  );
});
