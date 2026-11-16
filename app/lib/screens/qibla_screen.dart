import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/pickers.dart';

const double kaabaLat = 21.422487;
const double kaabaLng = 39.826206;

/// Initial great-circle bearing (degrees from true north) to the Kaaba.
double qiblaBearing(double lat, double lng) {
  double rad(double d) => d * math.pi / 180;
  final phi1 = rad(lat), phi2 = rad(kaabaLat);
  final dLng = rad(kaabaLng - lng);
  final y = math.sin(dLng) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) - math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Tilt-compensated compass heading (degrees) from gravity + magnetic vectors,
/// same maths as Android's SensorManager.getRotationMatrix / getOrientation.
double? headingFrom(List<double> g, List<double> m) {
  var ax = g[0], ay = g[1], az = g[2];
  final ex = m[0], ey = m[1], ez = m[2];
  var hx = ey * az - ez * ay, hy = ez * ax - ex * az, hz = ex * ay - ey * ax;
  final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
  if (normH < 0.1) return null;
  hx /= normH;
  hy /= normH;
  hz /= normH;
  final normA = math.sqrt(ax * ax + ay * ay + az * az);
  if (normA == 0) return null;
  ax /= normA;
  ay /= normA;
  az /= normA;
  final my = az * hx - ax * hz;
  final azimuth = math.atan2(hy, my) * 180 / math.pi;
  return (azimuth + 360) % 360;
}

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  List<double>? _g;
  List<double>? _m;
  double? _heading;
  bool _sensorError = false;

  @override
  void initState() {
    super.initState();
    try {
      _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) => _g = _lowPass([e.x, e.y, e.z], _g),
        onError: (_) => setState(() => _sensorError = true),
        cancelOnError: true,
      );
      _magSub = magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
        (e) {
          _m = _lowPass([e.x, e.y, e.z], _m);
          if (_g != null && _m != null) {
            final h = headingFrom(_g!, _m!);
            if (h != null && mounted) setState(() => _heading = h);
          }
        },
        onError: (_) => setState(() => _sensorError = true),
        cancelOnError: true,
      );
    } catch (_) {
      _sensorError = true;
    }
  }

  List<double> _lowPass(List<double> input, List<double>? prev) {
    if (prev == null) return input;
    const a = 0.15;
    return [for (var i = 0; i < 3; i++) prev[i] + a * (input[i] - prev[i])];
  }

  @override
  void dispose() {
    _accSub?.cancel();
    _magSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final theme = Theme.of(context);
    final st = state.settings;
    final bearing = qiblaBearing(st.lat, st.lng);
    final heading = _heading;
    final diff = heading == null ? null : ((bearing - heading + 540) % 360) - 180;
    final facing = diff != null && diff.abs() <= 5;

    return HeaderScaffold(
      title: s.t('qibla'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on, color: AppColors.gold),
              title: Text(st.locationName),
              subtitle: Text('${s.t('qibla_direction')}: ${bearing.toStringAsFixed(1)}° ${s.t('from_north')}'),
              trailing: TextButton(onPressed: () => useDeviceLocation(context, state), child: Text(s.t('update'))),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(alignment: Alignment.center, children: [
                Transform.rotate(
                  angle: -(heading ?? 0) * math.pi / 180,
                  child: CustomPaint(size: const Size(290, 290), painter: _DialPainter(theme.colorScheme.onSurface)),
                ),
                Transform.rotate(
                  angle: ((bearing - (heading ?? 0)) * math.pi / 180),
                  child: CustomPaint(size: const Size(290, 290), painter: _NeedlePainter(facing)),
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: facing ? AppColors.onTime : AppColors.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: const Icon(Icons.mosque, color: Colors.white),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (_sensorError || heading == null)
            Text(
              _sensorError ? s.t('no_compass') : s.t('compass_waiting'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            )
          else
            Column(children: [
              Text(
                facing ? s.t('facing_qibla') : '${s.t('turn')} ${diff!.abs().round()}° ${diff > 0 ? s.t('right') : s.t('left')}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: facing ? AppColors.onTime : theme.colorScheme.primary,
                ),
              ),
              Text('${s.t('heading')}: ${heading.round()}°', style: theme.textTheme.bodySmall),
            ]),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.info_outline, color: AppColors.gold),
                  const SizedBox(width: 8),
                  Text(s.t('calibration'), style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                Text(s.t('calibration_text')),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final Color color;
  _DialPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r - 2, Paint()..color = AppColors.emerald.withValues(alpha: 0.06));
    canvas.drawCircle(c, r - 2, Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    for (var i = 0; i < 72; i++) {
      final a = i * 5 * math.pi / 180;
      final long = i % 18 == 0;
      final p1 = c + Offset(math.sin(a), -math.cos(a)) * (r - 8);
      final p2 = c + Offset(math.sin(a), -math.cos(a)) * (r - (long ? 24 : 15));
      canvas.drawLine(p1, p2, Paint()
        ..color = color.withValues(alpha: long ? 0.8 : 0.35)
        ..strokeWidth = long ? 2.5 : 1);
    }
    const labels = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: i == 0 ? AppColors.missed : color, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = c + Offset(math.sin(a), -math.cos(a)) * (r - 42);
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) => old.color != color;
}

class _NeedlePainter extends CustomPainter {
  final bool facing;
  _NeedlePainter(this.facing);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final path = Path()
      ..moveTo(c.dx, c.dy - r + 30)
      ..lineTo(c.dx - 14, c.dy - 20)
      ..lineTo(c.dx + 14, c.dy - 20)
      ..close();
    canvas.drawPath(path, Paint()..color = facing ? AppColors.onTime : AppColors.gold);
    // Kaaba marker
    final k = Rect.fromCenter(center: Offset(c.dx, c.dy - r + 18), width: 18, height: 18);
    canvas.drawRect(k, Paint()..color = Colors.black87);
    canvas.drawRect(Rect.fromLTWH(k.left, k.top + 5, k.width, 3), Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(covariant _NeedlePainter old) => old.facing != facing;
}
