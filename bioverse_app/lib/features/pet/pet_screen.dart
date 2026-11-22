import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pet_art.dart';
import '../../models/conservation.dart';
import '../../models/gamification.dart';
import '../../models/json.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import '../missions/mission_tile.dart';
import '../missions/missions_screen.dart';
import 'adopt_pet_view.dart';
import 'shop_screen.dart';

/// Pet tab. Usability testing said the pet looked like "just a streak", so
/// this screen spells out what the pet is, how it grows, and what to do next.
class PetScreen extends StatelessWidget {
  const PetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pet'),
        actions: [
          PointsPill(points: session.points),
          const SizedBox(width: 6),
          StreakPill(days: session.streak.current),
          IconButton(
            tooltip: 'Pet shop',
            icon: const Icon(Icons.storefront_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
          ),
        ],
      ),
      body: !session.petLoaded
          ? const Center(child: CircularProgressIndicator())
          : session.pet == null
              ? const AdoptPetView()
              : RefreshIndicator(
                  onRefresh: session.refreshGame,
                  child: _PetBody(pet: session.pet!, streak: session.streak),
                ),
    );
  }
}

class _PetBody extends StatelessWidget {
  const _PetBody({required this.pet, required this.streak});
  final VirtualPet pet;
  final Streak streak;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      HabitatBackground(
        ecosystem: Ecosystem.parse(pet.species),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              _Tag(icon: Icons.favorite_rounded, label: pet.mood),
              const Spacer(),
              _Tag(icon: Icons.star_rounded, label: 'Level ${pet.level}'),
            ]),
            PetArt(species: pet.species, stage: pet.stage, health: pet.health, size: 180),
            Text(pet.name, style: t.headlineSmall),
            Text('${pet.coralType.isEmpty ? Ecosystem.parse(pet.species).label : pet.coralType} • ${pet.stage.label}',
                style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Panel(
        child: Column(children: [
          _Meter(label: 'Health', value: pet.health / 100, trailing: '${pet.health}%', color: _healthColor(pet.health)),
          const SizedBox(height: 12),
          _Meter(
            label: 'XP to level ${pet.level + 1}',
            value: pet.levelProgress,
            trailing: '${pet.xpToNextLevel} XP left',
            color: AppColors.primary,
          ),
          const SizedBox(height: 14),
          _StageTrack(stage: pet.stage),
        ]),
      ),
      const SizedBox(height: 16),
      Text('Take care of ${pet.name}', style: t.titleLarge),
      const SizedBox(height: 4),
      Text('Each action restores health and gives a little XP.', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: 10),
      _CareActions(pet: pet),
      const SizedBox(height: 16),
      const _HowItGrows(),
      const SizedBox(height: 16),
      _StreakCard(streak: streak),
      const SizedBox(height: 8),
      SectionHeader(
        'Eco missions',
        actionLabel: 'See all',
        onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsScreen())),
      ),
      Text('Biggest XP boost. Do a real eco action and upload a photo.', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: 8),
      AsyncView<Paged<EcoMission>>(
        load: () => context.read<Services>().game.missions(),
        isEmpty: (p) => p.items.isEmpty,
        empty: const Panel(child: Text('No missions available right now.')),
        builder: (context, page, _) => Column(children: [
          for (final m in page.items.take(3)) ...[MissionTile(mission: m), const SizedBox(height: 8)],
        ]),
      ),
    ]);
  }

  static Color _healthColor(int h) => h >= 70 ? AppColors.success : (h >= 40 ? AppColors.warning : AppColors.danger);
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy, fontSize: 12)),
        ]),
      );
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, required this.trailing, required this.color});
  final String label;
  final double value;
  final String trailing;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(children: [
      Row(children: [
        Text(label, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        Text(trailing, style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
      ]),
      const SizedBox(height: 6),
      Progress(value, color: color, height: 10),
    ]);
  }
}

class _StageTrack extends StatelessWidget {
  const _StageTrack({required this.stage});
  final GrowthStage stage;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(children: [
      for (final s in GrowthStage.values)
        Expanded(
          child: Column(children: [
            Icon(
              s.index < stage.index ? Icons.check_circle_rounded : (s == stage ? Icons.radio_button_checked_rounded : Icons.circle_outlined),
              color: s.index <= stage.index ? AppColors.primary : AppColors.border,
            ),
            const SizedBox(height: 2),
            Text(s.label,
                style: t.labelSmall?.copyWith(
                  fontWeight: s == stage ? FontWeight.w800 : FontWeight.w500,
                  color: s == stage ? AppColors.navy : AppColors.textMuted,
                )),
          ]),
        ),
    ]);
  }
}

class _CareActions extends StatefulWidget {
  const _CareActions({required this.pet});
  final VirtualPet pet;

  @override
  State<_CareActions> createState() => _CareActionsState();
}

class _CareActionsState extends State<_CareActions> {
  String? _busy;

  Future<void> _do(String type, String doneText) async {
    final session = context.read<Session>();
    setState(() => _busy = type);
    try {
      final updated = await context.read<Services>().game.interact(widget.pet, type);
      session.setPet(updated);
      session.refreshStreak();
      if (mounted) showMessage(context, doneText);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.pet.name;
    Widget action(String type, IconData icon, String label, String done) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(76),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: _busy == null ? () => _do(type, done) : null,
              child: _busy == type
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 26), const SizedBox(height: 4), Text(label)]),
            ),
          ),
        );
    return Row(children: [
      action('feed', Icons.restaurant_rounded, 'Feed', '$name enjoyed the meal!'),
      action('clean', Icons.cleaning_services_rounded, 'Clean', '$name is sparkling clean.'),
      action('pet', Icons.back_hand_rounded, 'Play', '$name loves you!'),
    ]);
  }
}

class _HowItGrows extends StatelessWidget {
  const _HowItGrows();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget row(IconData icon, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(body, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
              ]),
            ),
          ]),
        );
    return Panel(
      color: AppColors.mint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How your pet grows', style: t.titleMedium),
        const SizedBox(height: 4),
        row(Icons.favorite_rounded, 'Daily care keeps it healthy', 'Health drops over time. Feed, clean, or play each day.'),
        row(Icons.flag_rounded, 'Missions give the most XP', 'XP raises its level. Levels unlock new growth stages.'),
        row(Icons.spa_rounded, 'Stages: Hatchling → Juvenile → Adult → Elder', 'Each stage changes how your buddy looks.'),
        row(Icons.local_fire_department_rounded, 'Streaks', 'Do any eco action daily to grow your streak.'),
        row(Icons.storefront_rounded, 'Shop', 'Spend points on accessories, backgrounds, and streak freezes.'),
      ]),
    );
  }
}

class _StreakCard extends StatefulWidget {
  const _StreakCard({required this.streak});
  final Streak streak;

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard> {
  bool _loading = false;

  Future<void> _freeze() async {
    setState(() => _loading = true);
    try {
      await context.read<Services>().game.useStreakFreeze();
      if (!mounted) return;
      await context.read<Session>().refreshStreak();
      if (mounted) showMessage(context, 'Streak freeze active. Your streak is safe for a day.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = widget.streak;
    return Panel(
      color: AppColors.streakBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${s.current}-day streak', style: t.titleMedium),
              Text(
                s.activeToday ? 'Done for today. Come back tomorrow!' : 'Care for your pet or finish a mission to keep it going.',
                style: t.bodySmall,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: KeyValue('Longest', '${s.longest} days')),
          const SizedBox(width: 16),
          Expanded(child: KeyValue('Freezes', '${s.freezeCount}')),
        ]),
        if (s.freezeActive)
          const StatusChip('Freeze active', tone: Tone.info)
        else if (s.freezeCount > 0)
          OutlinedButton.icon(
            onPressed: _loading ? null : _freeze,
            icon: const Icon(Icons.ac_unit_rounded),
            label: const Text('Use a streak freeze'),
          ),
      ]),
    );
  }
}
