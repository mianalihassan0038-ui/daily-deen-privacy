import 'package:flutter/material.dart';

import '../app_state.dart';
import '../core/theme.dart';
import '../services/notifications.dart';
import '../widgets/islamic_art.dart';
import '../widgets/pickers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  final _name = TextEditingController();
  int _index = 0;

  static const _pages = [
    ('onb1_title', 'onb1_body', Icons.mosque),
    ('onb2_title', 'onb2_body', Icons.menu_book),
    ('onb3_title', 'onb3_body', Icons.self_improvement),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _name.text = AppScope.of(context).settings.userName;
    });
  }

  @override
  void dispose() {
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _finish(AppState state) async {
    state.settings.userName = _name.text.trim();
    state.settings.onboarded = true;
    state.saveSettings(reschedule: true);
    if (state.settings.notifications) {
      await NotificationService.instance.requestPermission();
      state.onScheduleChanged?.call(state);
    }
  }

  void _next(AppState state) {
    if (_index < _pages.length) {
      _page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
    } else {
      _finish(state);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final s = state.s;
    final total = _pages.length + 1;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final p in _pages) _IntroPage(title: s.t(p.$1), body: s.t(p.$2), icon: p.$3),
                _SetupPage(state: state, name: _name),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < total; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? AppColors.emerald : AppColors.emerald.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('onboarding_next'),
                      onPressed: () => _next(state),
                      icon: const Icon(Icons.arrow_forward),
                      iconAlignment: IconAlignment.end,
                      label: Text(_index == total - 1 ? s.t('start_app') : s.t('get_started')),
                    ),
                  ),
                  TextButton(
                    key: const Key('onboarding_skip'),
                    onPressed: () => _finish(state),
                    child: Text(s.t('skip_for_now')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  const _IntroPage({required this.title, required this.body, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: ClipPath(
            clipper: _WaveClipper(),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFBFE3CF), Color(0xFFEFF6EE), AppColors.cream],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                children: [
                  const Positioned(top: 70, right: 60, width: 46, height: 46, child: CustomPaint(painter: CrescentPainter())),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 30,
                    height: 190,
                    child: CustomPaint(painter: MosqueSkylinePainter(color: Color(0xFF13704C))),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 90,
                    child: Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                        child: Icon(icon, color: Colors.white, size: 34),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'serif'),
                ),
                const SizedBox(height: 12),
                Text(body, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 30)
      ..quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 20)
      ..quadraticBezierTo(size.width * 0.75, size.height - 40, size.width, size.height - 10)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SetupPage extends StatelessWidget {
  final AppState state;
  final TextEditingController name;
  const _SetupPage({required this.state, required this.name});

  @override
  Widget build(BuildContext context) {
    final s = state.s;
    final st = state.settings;
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          Text(s.t('setup_title'),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'serif')),
          const SizedBox(height: 6),
          Text(s.t('setup_body'), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            key: const Key('onboarding_name'),
            controller: name,
            textCapitalization: TextCapitalization.words,
            maxLength: 40,
            decoration: InputDecoration(labelText: s.t('your_name'), prefixIcon: const Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 8),
          Text(s.t('language'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('English')),
              ButtonSegment(value: true, label: Text('اردو')),
            ],
            selected: {st.urdu},
            onSelectionChanged: (v) {
              st.urdu = v.first;
              state.saveSettings();
            },
          ),
          const SizedBox(height: 20),
          Text(s.t('location'), style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_city),
                  title: Text(st.locationName),
                  subtitle: Text(s.t('choose_city')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => pickCity(context, state),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: Text(s.t('use_my_location')),
                  onTap: () => useDeviceLocation(context, state),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
