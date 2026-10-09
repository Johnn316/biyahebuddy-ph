import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/pressable.dart';

/// Hero SOS button (docs/DESIGN.md §8): red gradient circle with a soft glow
/// that slowly breathes. One loop only; static glow under reduce motion.
class SosButton extends StatefulWidget {
  const SosButton({super.key, required this.diameter, required this.onTap});

  final double diameter;
  final VoidCallback onTap;

  /// Layout room around the circle for the glow (× diameter).
  static const glowRoom = 1.16;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: AppMotion.sosBreath,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = widget.diameter;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox.square(
      dimension: d * SosButton.glowRoom,
      child: Center(
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, child) {
            final t = reduceMotion
                ? 0.5
                : AppMotion.breathe.transform(_breath.value);
            return DecoratedBox(
              key: const Key('sos-glow'),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: p.emergency.withValues(
                      alpha: lerpDouble(0.35, 0.55, t)!,
                    ),
                    blurRadius: lerpDouble(28, 44, t)! * (d / 200),
                    spreadRadius: lerpDouble(0, 6, t)! * (d / 200),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Semantics(
            button: true,
            label: 'SOS. Pindutin kapag naaksidente',
            excludeSemantics: true,
            child: Pressable(
              scale: 0.95,
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.3, -0.4),
                    radius: 1.0,
                    colors: [p.emergency, p.emergencyDeep],
                  ),
                  border: Border.all(
                    color: p.onEmergency.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: const Key('home-emergency'),
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      widget.onTap();
                    },
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(d * 0.16),
                        child: FittedBox(
                          child: Text(
                            'SOS',
                            style: context.text.displayLarge?.copyWith(
                              color: p.onEmergency,
                              fontSize: 64,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ),
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
