import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../models/gamification.dart';
import '../../state/services.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _period = 'all_time';

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Top supporters')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'this_month', label: Text('This month')),
              ButtonSegment(value: 'this_year', label: Text('This year')),
              ButtonSegment(value: 'all_time', label: Text('All time')),
            ],
            selected: {_period},
            onSelectionChanged: (s) => setState(() => _period = s.first),
          ),
        ),
        Expanded(
          child: AsyncView<List<LeaderboardEntry>>(
            key: ValueKey(_period),
            load: () => context.read<Services>().game.leaderboard(period: _period),
            isEmpty: (l) => l.isEmpty,
            empty: const EmptyState(title: 'No supporters in this period yet', icon: Icons.emoji_events_outlined),
            builder: (context, list, _) => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = list[i];
                final medal = switch (e.rank) { 1 => AppColors.coin, 2 => const Color(0xFFB0BEC5), 3 => const Color(0xFFCD7F32), _ => null };
                return Panel(
                  child: Row(children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: medal ?? AppColors.mint,
                      child: Text('${e.rank}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(e.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text('${e.units} units adopted', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                      ]),
                    ),
                    Text(Fmt.money(e.totalUsd, 'USD'), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }
}
