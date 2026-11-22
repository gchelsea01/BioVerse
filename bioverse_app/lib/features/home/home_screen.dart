import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pet_art.dart';
import '../../models/conservation.dart';
import '../../models/donation.dart';
import '../../models/gamification.dart';
import '../../models/json.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import '../auth/verify_email_screen.dart';
import '../donation/donation_history_screen.dart';
import '../impact/news_screens.dart';
import '../missions/mission_tile.dart';
import '../missions/missions_screen.dart';
import '../profile/notifications_screen.dart';
import '../projects/project_card.dart';
import '../shell/shell_controller.dart';

/// Home: kept short on purpose (feedback: make it minimal and informative).
/// Order: your impact → your pet → one mission → projects → community.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _version = 0;

  Future<void> _refresh() async {
    final session = context.read<Session>();
    setState(() => _version++);
    await Future.wait([session.refreshUser(), session.refreshGame()]);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    final t = Theme.of(context).textTheme;
    final services = context.read<Services>();
    final shell = context.read<ShellController>();

    return Scaffold(
      appBar: AppBar(
        title: const BrandMark(size: 24),
        actions: [
          PointsPill(points: session.points, onTap: () => shell.go(AppTab.pet)),
          const SizedBox(width: 6),
          StreakPill(days: session.streak.current, onTap: () => shell.go(AppTab.pet)),
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          key: ValueKey(_version),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text('Hi, ${user?.firstName ?? 'Guardian'}', style: t.headlineSmall),
            Text('Here is the nature you are helping restore.', style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
            if (user != null && !user.isEmailVerified) ...[
              const SizedBox(height: 12),
              _Banner(
                icon: Icons.mark_email_unread_rounded,
                text: 'Verify your email to secure your account.',
                action: 'Verify',
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen())),
              ),
            ],
            const SizedBox(height: 16),
            _ImpactCard(services: services),
            const SizedBox(height: 16),
            _PetCard(pet: session.pet, loaded: session.petLoaded, onOpen: () => shell.go(AppTab.pet)),
            SectionHeader(
              "Today's eco mission",
              actionLabel: 'All missions',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsScreen())),
            ),
            AsyncView<Paged<EcoMission>>(
              load: () => services.game.missions(),
              isEmpty: (p) => p.items.isEmpty,
              empty: const Panel(child: Text('No missions right now. Check back tomorrow!')),
              builder: (_, page, _) => MissionTile(mission: page.items.first),
            ),
            SectionHeader('Support a project', actionLabel: 'See all', onAction: () => shell.go(AppTab.donate)),
            AsyncView<Paged<Project>>(
              load: () => services.conservation.projects(status: 'open_for_donation', limit: 5),
              isEmpty: (p) => p.items.isEmpty,
              empty: const Panel(child: Text('No open projects right now.')),
              builder: (_, page, _) => SizedBox(
                height: 262,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => ProjectMiniCard(project: page.items[i]),
                ),
              ),
            ),
            const SectionHeader('Community impact'),
            AsyncView<ImpactSummary>(
              load: () => services.conservation.impact(),
              builder: (_, s, _) => Row(children: [
                Expanded(child: _StatBox(icon: Icons.water_rounded, color: AppColors.coral, value: Fmt.compact(s.corals), label: 'Corals adopted')),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(icon: Icons.park_rounded, color: AppColors.tree, value: Fmt.compact(s.trees), label: 'Trees planted')),
                const SizedBox(width: 8),
                Expanded(child: _StatBox(icon: Icons.groups_rounded, color: AppColors.primary, value: Fmt.compact(s.guardians), label: 'Guardians')),
              ]),
            ),
            AsyncView<Paged<NewsArticle>>(
              load: () => services.conservation.news(),
              loading: const SizedBox(),
              isEmpty: (p) => p.items.isEmpty,
              empty: const SizedBox(),
              builder: (context, page, _) => Column(children: [
                SectionHeader(
                  'Impact stories',
                  actionLabel: 'See all',
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsListScreen())),
                ),
                for (final a in page.items.take(2)) ...[NewsTile(article: a), const SizedBox(height: 8)],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.action, required this.onTap});
  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: AppColors.warning),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
        TextButton(onPressed: onTap, child: Text(action)),
      ]),
    );
  }
}

class _ImpactCard extends StatelessWidget {
  const _ImpactCard({required this.services});
  final Services services;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AsyncView<(Paged<Donation>, Paged<AdoptedUnit>)>(
      load: () async {
        final r = await Future.wait([
          services.donations.history(status: 'paid'),
          services.conservation.myCorals(),
        ]);
        return (r[0] as Paged<Donation>, r[1] as Paged<AdoptedUnit>);
      },
      loading: const Panel(child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))),
      builder: (context, data, _) {
        final (donations, corals) = data;
        final paid = donations.items;
        final currency = paid.isEmpty ? 'USD' : paid.first.currency;
        final total = paid.where((d) => d.currency == currency).fold<double>(0, (s, d) => s + d.grossAmount);
        final trees = paid.where((d) => d.type == 'tree_planting').length;
        return Panel(
          color: AppColors.mint,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('YOUR CONTRIBUTION', style: t.labelMedium?.copyWith(color: AppColors.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 2),
            Text(Fmt.money(total, currency), style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: InfoTile(icon: Icons.water_rounded, label: 'Corals adopted', value: '${corals.items.length}')),
              const SizedBox(width: 8),
              Expanded(child: InfoTile(icon: Icons.park_rounded, label: 'Tree/mangrove gifts', value: '$trees')),
            ]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationHistoryScreen())),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('See growth reports'),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({required this.pet, required this.loaded, required this.onOpen});
  final VirtualPet? pet;
  final bool loaded;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = pet;
    if (!loaded) return const SizedBox(height: 8);
    return HabitatBackground(
      ecosystem: Ecosystem.parse(p?.species),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          PetArt(species: p?.species ?? 'coral', stage: p?.stage ?? GrowthStage.juvenile, health: p?.health ?? 100, size: 104),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('YOUR ECO BUDDY', style: t.labelSmall?.copyWith(color: AppColors.textMuted, letterSpacing: 0.8)),
              Text(p?.name ?? 'Adopt a pet', style: t.titleLarge),
              const SizedBox(height: 4),
              if (p != null) ...[
                Text('Level ${p.level} • ${p.stage.label} • ${p.mood}', style: t.bodySmall),
                const SizedBox(height: 6),
                Progress(p.health / 100, height: 6, color: p.health >= 40 ? AppColors.success : AppColors.danger),
              ] else
                Text('It grows as you complete eco missions.', style: t.bodySmall),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.navy, minimumSize: const Size.fromHeight(42)),
                onPressed: onOpen,
                child: Text(p == null ? 'Adopt now' : 'Care for ${p.name}'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.icon, required this.color, required this.value, required this.label});
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(height: 6),
        Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, style: t.labelSmall?.copyWith(color: AppColors.textMuted)),
      ]),
    );
  }
}
