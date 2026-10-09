import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/screens/chat_screen.dart';
import '../../features/emergency/screens/emergency_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shell/main_shell.dart';
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
///
/// Home / Buddy (chat) / Na-flag (violation) / Profile are tabs of
/// [MainShell] (each keeps its own state + stack). Onboarding and Emergency
/// are full-screen routes above the tab bar.
final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  GoRoute tab(String path, Widget screen) =>
      GoRoute(path: path, builder: (_, _) => screen);

  return GoRouter(
    navigatorKey: rootKey,
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
      GoRoute(
        path: Routes.emergency,
        parentNavigatorKey: rootKey,
        builder: (_, _) => const EmergencyScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [tab(Routes.home, const HomeScreen())]),
          StatefulShellBranch(routes: [tab(Routes.chat, const ChatScreen())]),
          StatefulShellBranch(
            routes: [tab(Routes.violation, const ViolationScreen())],
          ),
          StatefulShellBranch(
            routes: [tab(Routes.profile, const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
});
