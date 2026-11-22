import 'package:bioverse_app/core/theme/app_theme.dart';
import 'package:bioverse_app/core/utils/format.dart';
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
    expect(p.ecosystem.donationType, 'tree_planting');
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

  testWidgets('placeholder pet renders without assets', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(body: PetArt(species: 'tree', stage: GrowthStage.adult)),
    ));
    await tester.pump();
    expect(find.byType(PetArt), findsOneWidget);
  });
}
