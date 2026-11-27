import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/conservation.dart';
import '../../models/gamification.dart';

/// Reef species that use the pink coral mascot; other ocean species use blue.
const _pinkSpecies = {'clownfish', 'seahorse'};

/// Mascot artwork (from the design team) for a pet species.
String petAssetFor(String species) {
  final eco = PetSpecies.ecosystemFor(species);
  return switch (eco) {
    Ecosystem.tree => 'assets/images/pet_tree.svg',
    Ecosystem.mangrove => 'assets/images/pet_coral_green.svg',
    Ecosystem.coral => _pinkSpecies.contains(species) ? 'assets/images/pet_coral_pink.svg' : 'assets/images/pet_coral_blue.svg',
  };
}

/// Shows the pet mascot. Younger stages are drawn smaller, and a pet that
/// needs care is shown slightly faded so its state is visible at a glance.
class PetArt extends StatelessWidget {
  const PetArt({super.key, required this.species, this.stage = GrowthStage.adult, this.health = 100, this.size = 160});

  final String species;
  final GrowthStage stage;
  final int health;
  final double size;

  static const _stageScale = [0.62, 0.76, 0.9, 1.0];

  @override
  Widget build(BuildContext context) {
    Widget art = SvgPicture.asset(petAssetFor(species), fit: BoxFit.contain);
    if (health < 40) {
      art = Opacity(opacity: 0.55, child: art);
    }
    return SizedBox.square(
      dimension: size,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(widthFactor: _stageScale[stage.index], heightFactor: _stageScale[stage.index], child: art),
      ),
    );
  }
}

/// Habitat backdrop for the pet card, decorated with the design team's
/// props: bubbles, starfish and shell on the reef; bush and bubbles in the
/// mangrove; bush and sunflower in the forest.
class HabitatBackground extends StatelessWidget {
  const HabitatBackground({super.key, required this.ecosystem, required this.child});
  final Ecosystem ecosystem;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = switch (ecosystem) {
      Ecosystem.coral => [const Color(0xFFDAF4F1), const Color(0xFFB9E4EC)],
      Ecosystem.mangrove => [const Color(0xFFDAF4F1), const Color(0xFFC4E5D2)],
      Ecosystem.tree => [const Color(0xFFE9F6E4), const Color(0xFFCDE7C1)],
    };
    final props = switch (ecosystem) {
      Ecosystem.coral => [
          _Prop('deco_bubble_shadow', left: 14, top: 12, size: 26),
          _Prop('deco_bubble', right: 22, top: 30, size: 18),
          _Prop('deco_starfish', left: 10, bottom: 6, size: 42),
          _Prop('deco_shell', right: 12, bottom: 6, size: 36),
        ],
      Ecosystem.mangrove => [
          _Prop('deco_bubble', right: 20, top: 14, size: 20),
          _Prop('deco_bush', left: 6, bottom: 4, size: 52),
          _Prop('deco_shell', right: 14, bottom: 6, size: 30),
        ],
      Ecosystem.tree => [
          _Prop('deco_sunflower', right: 16, top: 14, size: 30),
          _Prop('deco_bush', left: 6, bottom: 4, size: 56),
          _Prop('deco_bush', right: 8, bottom: 4, size: 44),
        ],
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
            ),
          ),
        ),
        for (final p in props)
          Positioned(
            left: p.left,
            right: p.right,
            top: p.top,
            bottom: p.bottom,
            child: SvgPicture.asset('assets/images/${p.name}.svg', width: p.size, height: p.size),
          ),
        child,
      ]),
    );
  }
}

class _Prop {
  const _Prop(this.name, {this.left, this.right, this.top, this.bottom, required this.size});
  final String name;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
}
