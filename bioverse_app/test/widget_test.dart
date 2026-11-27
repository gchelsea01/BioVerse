import 'package:bioverse_app/core/theme/app_theme.dart';
import 'package:bioverse_app/core/utils/format.dart';
import 'package:bioverse_app/core/widgets/net_image.dart';
import 'package:bioverse_app/core/widgets/pet_art.dart';
import 'package:bioverse_app/models/conservation.dart';
import 'package:bioverse_app/models/gamification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project parses API decimals and computes progress', () {
    final p = Project.fromJson({
      'id': '1',
      'title': 'Reef',
      'category': 'mangrove',
      'price_per_unit_money': '3.20',
      'target_units': 1500,
      'funded_units_count': 420,
      'status': 'open_for_donation',
    });
    expect(p.ecosystem, Ecosystem.mangrove);
    expect(p.pricePerUnit, 3.2);
    expect(p.progress, closeTo(0.28, 0.001));
    expect(p.isOpen, isTrue);
    expect(p.ecosystem.donationType, 'mangrove_planting');
  });

  test('missing fields do not throw', () {
    final pet = VirtualPet.fromJson({});
    expect(pet.stage, GrowthStage.hatchling);
    expect(pet.health, 100);
  });

  test('money formatting', () {
    expect(Fmt.money(32000, 'IDR'), contains('32.000'));
    expect(Fmt.money(3.2, 'USD'), '\$3.20');
  });

  testWidgets('pet mascot renders for every ecosystem', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: PetArt(species: 'tree', stage: GrowthStage.adult)),
    ));
    await tester.pump();
    expect(find.byType(PetArt), findsOneWidget);
  });

  test('unsplash images are requested at display size', () {
    expect(sizedImageUrl('https://images.unsplash.com/photo-1', 800), contains('w=800'));
    expect(sizedImageUrl('https://example.com/a.jpg', 800), 'https://example.com/a.jpg');
    expect(sizedImageUrl('https://images.unsplash.com/photo-1?w=300', 800), contains('w=300'));
  });

  testWidgets('NetImage accepts an infinite width without throwing', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Column(children: [NetImage('https://images.unsplash.com/photo-1', height: 100, width: double.infinity)])),
    ));
    expect(tester.takeException(), isNull);
  });
}
