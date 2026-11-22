import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/net_image.dart';
import '../../models/gamification.dart';
import 'mission_detail_screen.dart';

IconData missionIcon(EcoMission m) {
  final s = '${m.category ?? ''} ${m.title}'.toLowerCase();
  if (s.contains('tumbler') || s.contains('bottle') || s.contains('plastic')) return Icons.local_drink_rounded;
  if (s.contains('tree') || s.contains('plant')) return Icons.park_rounded;
  if (s.contains('clean') || s.contains('trash') || s.contains('waste')) return Icons.cleaning_services_rounded;
  if (s.contains('bike') || s.contains('walk') || s.contains('transport')) return Icons.directions_bike_rounded;
  return Icons.eco_rounded;
}

/// Row with reward and a clear "Start" button (Figma's was nearly invisible).
class MissionTile extends StatelessWidget {
  const MissionTile({super.key, required this.mission});
  final EcoMission mission;

  void _open(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MissionDetailScreen(mission: mission)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final m = mission;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            m.imageUrl != null
                ? NetImage(m.imageUrl, width: 48, height: 48, icon: missionIcon(m))
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                    child: Icon(missionIcon(m), color: AppColors.primary),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.toll_rounded, size: 14, color: AppColors.coin),
                  Text(' +${m.points} pts', style: t.labelMedium),
                  const SizedBox(width: 10),
                  const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                  Text(' +${m.xp} XP', style: t.labelMedium),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _open(context),
              style: FilledButton.styleFrom(minimumSize: const Size(72, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
              child: const Text('Start'),
            ),
          ]),
        ),
      ),
    );
  }
}
