import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../shared/widgets/pressable.dart';

/// Big circular SOS button with slowly pulsing concentric rings.
/// Rings are static when the system asks to reduce motion.
class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.diameter,
    required this.onTap,
    this.layoutSpread = ringSpread,
  });

  final double diameter;
  final VoidCallback onTap;

  /// How far the outermost ring reaches (× diameter).
  static const ringSpread = 1.42;

  /// Layout box (× diameter). Smaller than [ringSpread] on short screens:
  /// the rings then glow past the box without taking layout space.
  final double layoutSpread;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final d = widget.diameter;
    final box = d * widget.layoutSpread;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SizedBox.square(
      dimension: box,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 3 concentric rings, staggered.
          for (var i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) {
                final t = reduceMotion
                    ? (i + 1) / 3.5
                    : (_pulse.value + i / 3) % 1.0;
                final scale = 1 + (SosButton.ringSpread - 1) * t;
                return OverflowBox(
                  maxWidth: d * SosButton.ringSpread,
                  maxHeight: d * SosButton.ringSpread,
                  child: Container(
                    width: d * scale,
                    height: d * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.emergency.withValues(alpha: 0.16 * (1 - t)),
                    ),
                  ),
                );
              },
            ),
          Semantics(
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
                  gradient: p.emergencyGradient,
                  boxShadow: [
                    BoxShadow(
                      color: p.emergency.withValues(alpha: 0.35),
                      blurRadius: d * 0.18,
                      offset: Offset(0, d * 0.06),
                    ),
                  ],
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
                        padding: EdgeInsets.all(d * 0.12),
                        child: FittedBox(
                          child: Text(
                            'SOS',
                            style: context.text.displayLarge?.copyWith(
                              color: p.onEmergency,
                              fontSize: 64,
                              letterSpacing: 2,
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
        ],
      ),
    );
  }
}
