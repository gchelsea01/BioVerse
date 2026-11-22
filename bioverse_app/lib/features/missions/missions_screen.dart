import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../models/gamification.dart';
import '../../models/json.dart';
import '../../state/services.dart';
import 'mission_tile.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Eco missions')),
      body: AsyncView<Paged<EcoMission>>(
        load: () => context.read<Services>().game.missions(),
        isEmpty: (p) => p.items.isEmpty,
        empty: const EmptyState(title: 'No missions right now', message: 'New missions are added every week.', icon: Icons.flag_outlined),
        builder: (context, page, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Panel(
              color: AppColors.mint,
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Do a real-world eco action, snap a photo as proof, and earn points plus XP for your pet. '
                    'Photos are checked automatically.',
                    style: t.bodySmall,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            for (final m in page.items) ...[MissionTile(mission: m), const SizedBox(height: 8)],
          ]),
        ),
      ),
    );
  }
}
