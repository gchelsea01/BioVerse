import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand.dart';
import '../../state/session.dart';

class _Page {
  const _Page(this.asset, this.icon, this.title, this.body);
  final String asset;
  final IconData icon;
  final String title;
  final String body;
}

const _pages = [
  _Page(
    'onboard_donate',
    Icons.volunteer_activism_rounded,
    'Donate to restore nature',
    'Adopt a coral fragment, plant a mangrove, or grow a tree. Every unit goes to a real restoration project, from ridge to reef.',
  ),
  _Page(
    'onboard_track',
    Icons.photo_library_rounded,
    'See real progress',
    'Field teams send verified photos at month 1, 3 and 6, so you can see exactly what your donation did.',
  ),
  _Page(
    'onboard_pet',
    Icons.pets_rounded,
    'Grow your eco buddy',
    'Finish eco-missions like using a tumbler to earn points. Your virtual pet levels up as you help the planet.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  bool get _last => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              const BrandMark(size: 26),
              const Spacer(),
              if (!_last)
                TextButton(onPressed: () => context.read<Session>().finishOnboarding(), child: const Text('Skip')),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(appTagline, style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final p = _pages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(height: 240, width: 260, child: _Illustration(index: i, icon: p.icon)),
                    const SizedBox(height: 32),
                    Text(p.title, textAlign: TextAlign.center, style: t.headlineSmall),
                    const SizedBox(height: 12),
                    Text(p.body,
                        textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: AppColors.textMuted, height: 1.4)),
                  ]),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.primary : AppColors.mintStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: FilledButton(
              onPressed: () {
                if (_last) {
                  context.read<Session>().finishOnboarding();
                } else {
                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                }
              },
              child: Text(_last ? 'Get started' : 'Next'),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Onboarding scenes composed from the design team's mascots and props
/// (no dedicated onboarding illustrations were provided).
class _Illustration extends StatelessWidget {
  const _Illustration({required this.index, required this.icon});
  final int index;
  final IconData icon;

  Widget _svg(String name, double size) => SvgPicture.asset('assets/images/$name.svg', width: size, height: size);

  @override
  Widget build(BuildContext context) {
    final items = switch (index) {
      // Donate: the three ecosystems you can fund.
      0 => [
          Positioned(left: 0, bottom: 20, child: _svg('pet_coral_blue', 100)),
          Positioned(right: 0, bottom: 20, child: _svg('pet_tree', 110)),
          Positioned(left: 80, top: 10, child: _svg('pet_coral_green', 96)),
        ],
      // Track: a progress card with the coral growing.
      1 => [
          Positioned(left: 8, bottom: 40, child: _svg('pet_coral_pink', 56)),
          Positioned(left: 72, bottom: 40, child: _svg('pet_coral_pink', 80)),
          Positioned(right: 4, bottom: 40, child: _svg('pet_coral_pink', 108)),
          Positioned(left: 20, top: 20, child: Icon(icon, size: 40, color: AppColors.accent)),
          Positioned(right: 30, top: 24, child: _svg('deco_bubble', 26)),
        ],
      // Pet: the buddy with its reef props.
      _ => [
          Positioned(left: 55, bottom: 18, child: _svg('pet_coral_blue', 150)),
          Positioned(left: 0, bottom: 14, child: _svg('deco_starfish', 54)),
          Positioned(right: 0, bottom: 14, child: _svg('deco_shell', 48)),
          Positioned(right: 22, top: 16, child: _svg('deco_bubble_shadow', 30)),
          Positioned(left: 26, top: 40, child: _svg('deco_bubble', 20)),
        ],
    };
    return Stack(clipBehavior: Clip.none, children: [
      Positioned.fill(
        child: Container(decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle)),
      ),
      ...items,
    ]);
  }
}
