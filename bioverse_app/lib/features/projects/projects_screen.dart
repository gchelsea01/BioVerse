import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../models/conservation.dart';
import '../../models/gamification.dart';
import '../../models/json.dart';
import '../../state/services.dart';
import '../donation/donation_history_screen.dart';
import '../profile/leaderboard_screen.dart';
import 'project_card.dart';

/// "Donate" tab: pick an ecosystem, browse projects, see top supporters.
class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  Ecosystem? _filter;

  @override
  Widget build(BuildContext context) {
    final services = context.read<Services>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donate'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 12)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DonationHistoryScreen())),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('My donations'),
            ),
          ),
        ],
      ),
      body: AsyncView<(Paged<Project>, List<LeaderboardEntry>)>(
        key: ValueKey(_filter),
        load: () async {
          final results = await Future.wait([
            services.conservation.projects(ecosystem: _filter),
            services.game.leaderboard().catchError((_) => <LeaderboardEntry>[]),
          ]);
          return (results[0] as Paged<Project>, results[1] as List<LeaderboardEntry>);
        },
        builder: (context, data, reload) {
          final (page, ranking) = data;
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (ranking.isNotEmpty) ...[_TopSupporters(ranking: ranking.take(3).toList()), const SizedBox(height: 16)],
                _EcosystemFilter(value: _filter, onChanged: (v) => setState(() => _filter = v)),
                const SizedBox(height: 12),
                if (page.items.isEmpty)
                  EmptyState(
                    title: 'No ${_filter?.label.toLowerCase() ?? ''} projects open yet',
                    message: 'New restoration projects are added regularly. Check back soon.',
                    icon: _filter?.icon ?? Icons.eco_outlined,
                  )
                else
                  for (final p in page.items) ...[ProjectCard(project: p), const SizedBox(height: 12)],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EcosystemFilter extends StatelessWidget {
  const _EcosystemFilter({required this.value, required this.onChanged});
  final Ecosystem? value;
  final ValueChanged<Ecosystem?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        _chip(context, null, 'All', Icons.public_rounded),
        for (final e in Ecosystem.values) _chip(context, e, e.label, e.icon),
      ]),
    );
  }

  Widget _chip(BuildContext context, Ecosystem? e, String label, IconData icon) {
    final selected = value == e;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onChanged(e),
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : AppColors.navy),
        label: Text(label),
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.navy, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TopSupporters extends StatelessWidget {
  const _TopSupporters({required this.ranking});
  final List<LeaderboardEntry> ranking;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Panel(
      color: AppColors.mint,
      child: Column(children: [
        Row(children: [
          const Icon(Icons.emoji_events_rounded, color: AppColors.coin),
          const SizedBox(width: 8),
          Expanded(child: Text('Top supporters', style: t.titleMedium)),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
            child: const Text('See all'),
          ),
        ]),
        for (final r in ranking)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              SizedBox(width: 24, child: Text('${r.rank}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
              const CircleAvatar(radius: 14, backgroundColor: Colors.white, child: Icon(Icons.person_rounded, size: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(r.name, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
              Text(Fmt.money(r.totalUsd, 'USD'), style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
        if (ranking.isEmpty) const StatusChip('No supporters yet'),
      ]),
    );
  }
}
