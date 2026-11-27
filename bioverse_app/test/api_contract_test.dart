import 'dart:convert';
import 'dart:io';

import 'package:bioverse_app/core/widgets/pet_art.dart';
import 'package:bioverse_app/models/conservation.dart';
import 'package:bioverse_app/models/gamification.dart';
import 'package:bioverse_app/models/json.dart';
import 'package:bioverse_app/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parses real responses captured from api.ourprojects.my.id (test/fixtures),
/// so a backend shape change shows up here instead of as a blank screen.
Object? fixture(String name) => jsonDecode(File('test/fixtures/$name.json').readAsStringSync());

void main() {
  test('projects cover all three ecosystems with location', () {
    final page = Paged.from(fixture('projects'), Project.fromJson);
    expect(page.items, isNotEmpty);
    expect(page.items.map((p) => p.ecosystem).toSet(), containsAll(Ecosystem.values));
    for (final p in page.items) {
      expect(p.title, isNotEmpty);
      expect(p.locationName, isNotNull);
      expect(p.pricePerUnit, greaterThan(0));
    }
  });

  test('missions parse with duration and image', () {
    final page = Paged.from(fixture('missions'), EcoMission.fromJson);
    expect(page.items, isNotEmpty);
    expect(page.items.every((m) => m.estimatedMinutes != null && m.points > 0), isTrue);
  });

  test('pet parses exact XP to next level', () {
    final pets = list(fixture('pets'), VirtualPet.fromJson);
    expect(pets, isNotEmpty);
    final p = pets.first;
    expect(p.xpToNextLevel, VirtualPet.xpForLevel(p.level + 1) - p.xp);
    expect(p.levelProgress, inInclusiveRange(0, 1));
  });

  test('species map to ocean, mangrove, and forest habitats', () {
    final species = list(fixture('species'), PetSpecies.fromJson);
    expect(species.map((s) => s.ecosystem).toSet(), containsAll(Ecosystem.values));
    for (final s in species) {
      expect(File(petAssetFor(s.id)).existsSync(), isTrue, reason: '${s.id} -> ${petAssetFor(s.id)}');
    }
  });

  test('stats, submissions, notifications, news, streak parse', () {
    final stats = UserStats.fromJson(fixture('stats') as Json);
    expect(stats.missionsCompleted, greaterThanOrEqualTo(0));
    final subs = Paged.from(fixture('mission_submissions'), MissionSubmission.fromJson).items;
    expect(subs.every((s) => s.missionId != null && s.status.isNotEmpty), isTrue);
    Paged.from(fixture('notifications'), AppNotification.fromJson);
    expect(Paged.from(fixture('news'), NewsArticle.fromJson).items, isNotEmpty);
    Streak.fromJson(fixture('streak') as Json);
  });

  test('units/my: future-dated reports are not treated as received', () {
    // Shape from conservationUnitItem in the backend; live list is empty for the test user.
    final now = DateTime.now();
    final unit = AdoptedUnit.fromJson({
      'id': 'u1',
      'unit_code': 'MGV-001',
      'category': 'mangrove',
      'project_name': 'Tanjung Lesung Mangrove Shield',
      'species_name': 'Rhizophora',
      'location_name': 'Tanjung Lesung Coastal Mangrove',
      'quantity': 3,
      'lifecycle_status': 'planted',
      'health_status': 'healthy',
      'planted_at': now.subtract(const Duration(days: 40)).toIso8601String(),
      'milestones': [
        {'milestone_month': 3, 'media_url': 'b', 'health_status': 'healthy', 'captured_at': now.add(const Duration(days: 50)).toIso8601String()},
        {'milestone_month': 1, 'media_url': 'a', 'health_status': 'healthy', 'captured_at': now.subtract(const Duration(days: 10)).toIso8601String()},
        // Placeholder the backend sends before the field team visits; date already passed.
        {'milestone_month': 6, 'media_url': 'c', 'health_status': 'scheduled', 'is_verified_healthy': false,
         'captured_at': now.subtract(const Duration(days: 1)).toIso8601String()},
      ],
    });
    expect(unit.ecosystem, Ecosystem.mangrove);
    expect(unit.quantity, 3);
    expect(unit.milestones.map((m) => m.month), [1, 3, 6]);
    expect(unit.milestones[0].isReceived, isTrue);
    expect(unit.milestones[1].isReceived, isFalse);
    expect(unit.milestones[2].isReceived, isFalse);
  });

  test('missing completed_today is filled from submissions', () {
    final m = EcoMission.fromJson({'id': 'm1', 'title': 'T', 'points_reward': 10});
    expect(m.completedToday, isFalse);
    final filled = m.withProgress(completedToday: true, lastStatus: 'verified');
    expect(filled.completedToday, isTrue);
    expect(filled.lastStatus, 'verified');
  });
}
