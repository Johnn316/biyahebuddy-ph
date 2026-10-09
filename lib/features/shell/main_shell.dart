import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

typedef _Tab = ({String key, String label, IconData icon, IconData active});

const _tabs = <_Tab>[
  (
    key: 'tab-home',
    label: 'Home',
    icon: CupertinoIcons.house,
    active: CupertinoIcons.house_fill,
  ),
  (
    key: 'tab-chat',
    label: 'Buddy',
    icon: CupertinoIcons.chat_bubble_2,
    active: CupertinoIcons.chat_bubble_2_fill,
  ),
  (
    key: 'tab-violation',
    label: 'Na-flag',
    icon: CupertinoIcons.flag,
    active: CupertinoIcons.flag_fill,
  ),
  (
    key: 'tab-profile',
    label: 'Profile',
    icon: CupertinoIcons.person_crop_circle,
    active: CupertinoIcons.person_crop_circle_fill,
  ),
];

/// Tabs: Home · Buddy · Na-flag · Profile, with a floating frosted tab bar.
/// Body extends behind the bar; screens pad by MediaQuery bottom padding.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: FrostedTabBar(
        index: shell.currentIndex,
        onSelect: (i) {
          HapticFeedback.selectionClick();
          // Re-tapping the current tab pops it back to its first screen.
          shell.goBranch(i, initialLocation: i == shell.currentIndex);
        },
      ),
    );
  }
}

class FrostedTabBar extends StatelessWidget {
  const FrostedTabBar({super.key, required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final (i, t) in _tabs.indexed)
                          Expanded(
                            child: _TabItem(
                              tab: t,
                              selected: i == index,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? context.colors.primary : context.palette.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key(tab.key),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? tab.active : tab.icon, color: color, size: 26),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tab.label,
                  maxLines: 1,
                  style: context.text.labelMedium?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
