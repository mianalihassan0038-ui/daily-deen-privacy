import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/quran_repo.dart';
import '../widgets/islamic_art.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Warm up the Quran index while the splash is visible.
    QuranRepository.instance.ensureLoaded().catchError((_) {});
    _timer = Timer(const Duration(milliseconds: 1700), widget.onDone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).s;
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.emerald,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: GeometricPatternPainter())),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: CustomPaint(painter: MosqueSkylinePainter(color: Color(0x33000000))),
            ),
            const Positioned(top: 0, left: 36, width: 34, height: 110, child: CustomPaint(painter: LanternPainter())),
            const Positioned(top: 0, right: 36, width: 34, height: 110, child: CustomPaint(painter: LanternPainter())),
            Center(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.0).animate(fade),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 110, height: 110, child: CustomPaint(painter: CrescentPainter())),
                      const SizedBox(height: 18),
                      Text(
                        s.t('app_name'),
                        style: const TextStyle(
                          color: AppColors.goldLight,
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(s.t('splash_tagline'),
                          textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 64,
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.gold),
                  ),
                  const SizedBox(height: 10),
                  Text(s.t('loading'), style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
