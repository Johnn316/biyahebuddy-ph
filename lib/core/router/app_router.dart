import 'package:go_router/go_router.dart';

import '../../features/chat/screens/chat_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/violation/screens/violation_screen.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const emergency = '/emergency';
  static const violation = '/violation';
  static const chat = '/chat';
  static const profile = '/profile';
}

// TODO(frontend): redirect to /onboarding when ProfileRepository.load() is null.
final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(
      path: Routes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: Routes.emergency, builder: (_, _) => const EmergencyScreen()),
    GoRoute(path: Routes.violation, builder: (_, _) => const ViolationScreen()),
    GoRoute(path: Routes.chat, builder: (_, _) => const ChatScreen()),
    GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
  ],
);
