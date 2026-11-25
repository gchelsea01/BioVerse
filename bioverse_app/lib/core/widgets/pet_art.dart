import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/conservation.dart';
import '../../models/gamification.dart';
import '../theme/app_colors.dart';

/// Shows the pet. Uses `assets/images/pet_<species>_<stage>.png` once the
/// artist delivers it (see docs/ASSETS.md); until then draws a vector
/// placeholder that already grows with the stage and reacts to health.
class PetArt extends StatelessWidget {
  const PetArt({super.key, required this.species, this.stage = GrowthStage.adult, this.health = 100, this.size = 160});

  final String species;
  final GrowthStage stage;
  final int health;
  final double size;

  Ecosystem get ecosystem => PetSpecies.ecosystemFor(species);

  @override
  Widget build(BuildContext context) {
    final placeholder = CustomPaint(
      size: Size.square(size),
      painter: _PetPainter(ecosystem: ecosystem, stage: stage, health: health),
    );
    return SizedBox.square(
      dimension: size,
      child: Image.asset(
        'assets/images/pet_${ecosystem.api}_${stage.name}.png',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _PetPainter extends CustomPainter {
  _PetPainter({required this.ecosystem, required this.stage, required this.health});
  final Ecosystem ecosystem;
  final GrowthStage stage;
  final int health;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Younger stages are drawn smaller, centered at the bottom.
    final scale = 0.55 + stage.index * 0.15;
    canvas.save();
    canvas.translate(s * (1 - scale) / 2, s * (1 - scale) * 0.85);
    canvas.scale(scale);

    final base = switch (ecosystem) {
      Ecosystem.coral => const Color(0xFF6EA8F0),
      Ecosystem.mangrove => const Color(0xFF4DB6A0),
      Ecosystem.tree => const Color(0xFF7BC46A),
    };
    final dark = Color.lerp(base, Colors.black, 0.25)!;
    final paint = Paint()..color = base;

    // Ground shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.5, s * 0.93), width: s * 0.6, height: s * 0.08),
      Paint()..color = Colors.black.withValues(alpha: 0.08),
    );

    switch (ecosystem) {
      case Ecosystem.coral:
        // Branching coral: limbs fan out from the body and fork at the tips,
        // so it reads as coral rather than fingers. Older stages get more limbs.
        final limb = Paint()
          ..color = base
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.075;
        final twig = Paint()
          ..color = base
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.05;
        final tip = Paint()..color = Color.lerp(base, Colors.white, 0.45)!;
        final origin = Offset(s * 0.5, s * 0.55);
        final limbs = 3 + stage.index;
        for (var i = 0; i < limbs; i++) {
          final t = limbs == 1 ? 0.5 : i / (limbs - 1);
          final angle = -math.pi / 2 + (t - 0.5) * 1.5; // fan from left to right
          final len = s * (0.26 + 0.08 * math.sin(t * math.pi));
          final end = origin + Offset(math.cos(angle), math.sin(angle)) * len;
          canvas.drawLine(origin, end, limb);
          for (final fork in [-0.45, 0.45]) {
            final a = angle + fork;
            final twigEnd = end + Offset(math.cos(a), math.sin(a)) * (s * 0.09);
            canvas.drawLine(end, twigEnd, twig);
            canvas.drawCircle(twigEnd, s * 0.028, tip);
          }
        }
      case Ecosystem.mangrove:
        final rootPaint = Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.035
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final dx = s * (0.3 + i * 0.13);
          final path = Path()
            ..moveTo(s * 0.5, s * 0.7)
            ..quadraticBezierTo(dx, s * 0.72, dx, s * 0.9);
          canvas.drawPath(path, rootPaint);
        }
        canvas.drawCircle(Offset(s * 0.5, s * 0.3), s * (0.18 + stage.index * 0.02), paint);
        canvas.drawCircle(Offset(s * 0.33, s * 0.38), s * 0.13, paint);
        canvas.drawCircle(Offset(s * 0.67, s * 0.38), s * 0.13, paint);
      case Ecosystem.tree:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.44, s * 0.45, s * 0.12, s * 0.42), Radius.circular(s * 0.04)),
          Paint()..color = const Color(0xFF9B6B43),
        );
        canvas.drawCircle(Offset(s * 0.5, s * 0.3), s * (0.2 + stage.index * 0.02), paint);
        canvas.drawCircle(Offset(s * 0.32, s * 0.4), s * 0.14, paint);
        canvas.drawCircle(Offset(s * 0.68, s * 0.4), s * 0.14, paint);
    }

    // Body with face
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.18, s * 0.45, s * 0.64, s * 0.42),
      Radius.circular(s * 0.2),
    );
    canvas.drawRRect(body, Paint()..color = base);
    canvas.drawRRect(
      body.deflate(s * 0.03).shift(Offset(-s * 0.02, -s * 0.02)),
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    final eye = Paint()..color = AppColors.navy;
    final eyeY = s * 0.62;
    if (health < 40) {
      // Tired eyes
      final stroke = Paint()
        ..color = AppColors.navy
        ..strokeWidth = s * 0.02
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(s * 0.36, eyeY), Offset(s * 0.42, eyeY), stroke);
      canvas.drawLine(Offset(s * 0.58, eyeY), Offset(s * 0.64, eyeY), stroke);
    } else {
      canvas.drawCircle(Offset(s * 0.39, eyeY), s * 0.035, eye);
      canvas.drawCircle(Offset(s * 0.61, eyeY), s * 0.035, eye);
      canvas.drawCircle(Offset(s * 0.4, eyeY - s * 0.012), s * 0.012, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(s * 0.62, eyeY - s * 0.012), s * 0.012, Paint()..color = Colors.white);
    }
    final cheek = Paint()..color = const Color(0xFFFF9AA2).withValues(alpha: 0.6);
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.31, s * 0.69), width: s * 0.08, height: s * 0.045), cheek);
    canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.69, s * 0.69), width: s * 0.08, height: s * 0.045), cheek);

    final mouth = Paint()
      ..color = AppColors.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.018
      ..strokeCap = StrokeCap.round;
    final happy = health >= 40;
    final mouthPath = Path()
      ..moveTo(s * 0.46, s * 0.7)
      ..quadraticBezierTo(s * 0.5, happy ? s * 0.74 : s * 0.67, s * 0.54, s * 0.7);
    canvas.drawPath(mouthPath, mouth);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PetPainter old) =>
      old.ecosystem != ecosystem || old.stage != stage || old.health != health;
}

/// Soft habitat backdrop for the pet card; replaced by artist PNGs later.
class HabitatBackground extends StatelessWidget {
  const HabitatBackground({super.key, required this.ecosystem, required this.child});
  final Ecosystem ecosystem;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = switch (ecosystem) {
      Ecosystem.coral => [const Color(0xFFD9EEF8), const Color(0xFFB7DDE9)],
      Ecosystem.mangrove => [const Color(0xFFDDF1EA), const Color(0xFFBFE0CF)],
      Ecosystem.tree => [const Color(0xFFE6F4DC), const Color(0xFFC8E6B5)],
    };
    final file = switch (ecosystem) {
      Ecosystem.coral => 'habitat_reef',
      Ecosystem.mangrove => 'habitat_mangrove',
      Ecosystem.tree => 'habitat_forest',
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
        Positioned.fill(
          child: Image.asset('assets/images/$file.png', fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
        ),
        child,
      ]),
    );
  }
}
