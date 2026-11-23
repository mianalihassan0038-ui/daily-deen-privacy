import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import 'islamic_art.dart';

/// Green curved page header with title, optional back button and actions.
class ScreenHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final bool showBack;
  final Widget? bottom;
  const ScreenHeader({super.key, required this.title, this.actions = const [], this.showBack = false, this.bottom});

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    return IslamicHeaderBackground(
      skyline: false,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 14),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      child: canPop ? const BackButton(color: Colors.white) : null,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppScope.of(context).settings.urdu
                            ? const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)
                            : displayStyle(size: 21, color: Colors.white),
                      ),
                    ),
                    if (actions.isEmpty) const SizedBox(width: 48) else Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ),
              ),
              if (bottom != null) ...[const SizedBox(height: 8), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Scaffold with a [ScreenHeader] used for pushed (secondary) screens.
class HeaderScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? headerBottom;
  const HeaderScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.headerBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          ScreenHeader(title: title, showBack: true, actions: actions, bottom: headerBottom),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// White pill segmented control used inside green headers (Today / Week / Month).
class HeaderTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const HeaderTabs({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(30)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                key: Key('header_tab_$i'),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: i == index ? AppColors.emerald : Colors.white,
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

class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ),
          if (actionLabel != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(actionLabel!, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                  Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.primary),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular progress ring with centred child.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double stroke;
  final Widget? child;
  final Color? color;
  final Color? trackColor;
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 80,
    this.stroke = 8,
    this.child,
    this.color,
    this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, stroke, c, trackColor ?? c.withValues(alpha: 0.14)),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double stroke;
  final Color color;
  final Color track;
  _RingPainter(this.value, this.stroke, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(r, 0, math.pi * 2, false, Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke);
    if (value > 0) {
      canvas.drawArc(r, -math.pi / 2, math.pi * 2 * value, false, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.value != value || old.color != color || old.track != track || old.stroke != stroke;
}

/// Small icon badge in a tinted circle.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconBadge(this.icon, {super.key, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// Error message with a Retry button.
class RetryState extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const RetryState({super.key, required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const Key('retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(s.t('retry')),
          ),
        ]),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Simple vertical bar chart (values 0..1).
class MiniBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double height;
  final int? highlight;
  const MiniBarChart({super.key, required this.values, required this.labels, this.height = 120, this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height + 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${(values[i] * 100).round()}%', style: const TextStyle(fontSize: 9)),
                  const SizedBox(height: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: values[i].clamp(0.0, 1.0).toDouble()),
                    duration: const Duration(milliseconds: 500),
                    builder: (context, v, _) => Container(
                      width: 16,
                      height: 4 + (height - 20) * v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: i == highlight
                              ? [AppColors.gold, AppColors.goldLight]
                              : [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(labels[i], maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Shows a short confirmation at the bottom of the screen.
void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
}


/// "Done" wax seal: an 8-point star (Rub el Hizb) on a round seal. Pops in
/// with a small stamp animation when it appears.
class Seal extends StatelessWidget {
  final double size;
  final Color color;
  final Color starColor;
  const Seal({super.key, this.size = 30, this.color = AppColors.emeraldMid, this.starColor = AppColors.goldLight});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.35, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (c, scale, child) => Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _SealPainter(color, starColor)),
      ),
    );
  }
}

/// Empty seal outline (not done yet).
class SealOutline extends StatelessWidget {
  final double size;
  final Color? color;
  const SealOutline({super.key, this.size = 30, this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color ?? Theme.of(context).colorScheme.outlineVariant, width: 1.6),
        ),
      );
}

class _SealPainter extends CustomPainter {
  final Color color;
  final Color starColor;
  _SealPainter(this.color, this.starColor);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = color);
    canvas.drawCircle(
      c,
      r - 2,
      Paint()
        ..color = starColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    // 8-point star = two squares, one rotated by 45°.
    final half = r * 0.42;
    final star = Path();
    for (final rot in [0.0, math.pi / 4]) {
      final pts = [
        for (var k = 0; k < 4; k++)
          c + Offset(math.cos(rot + k * math.pi / 2 + math.pi / 4), math.sin(rot + k * math.pi / 2 + math.pi / 4)) * half * math.sqrt2,
      ];
      star.addPolygon(pts, true);
    }
    canvas.drawPath(star, Paint()..color = starColor);
    canvas.drawCircle(c, r * 0.14, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SealPainter old) => old.color != color || old.starColor != starColor;
}

/// Tasbeeh "rosary line": [total] beads, the first [filled] coloured.
class RosaryLine extends StatelessWidget {
  final int filled;
  final int total;
  const RosaryLine({super.key, required this.filled, this.total = 33});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      key: const Key('rosary_line'),
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? AppColors.emeraldMid : Colors.transparent,
              border: Border.all(color: i < filled ? AppColors.emeraldMid : theme.colorScheme.outlineVariant, width: 1.5),
            ),
          ),
      ],
    );
  }
}
