import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/conservation.dart';
import '../../state/services.dart';

const _milestones = [1, 3, 6];

/// Growth timeline. Each report is labelled "Month N" with its date and
/// "Report x of 3", answering the usability question "is this the 2nd or
/// 3rd month?".
class AdoptedUnitScreen extends StatelessWidget {
  const AdoptedUnitScreen({super.key, required this.unit});
  final AdoptedUnit unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = unit;
    return Scaffold(
      appBar: AppBar(title: Text(u.nickname ?? 'My coral')),
      body: AsyncView<List<MilestoneUpdate>>(
        load: () => context.read<Services>().conservation.timeline(u.id),
        builder: (context, updates, reload) {
          final byMonth = {for (final m in updates) m.month: m};
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
              Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(u.projectName, style: t.titleMedium)),
                    StatusChip.forStatus(u.healthStatus),
                  ]),
                  const SizedBox(height: 10),
                  KeyValue('Species', u.speciesName),
                  KeyValue('Fragment code', u.code),
                  if (u.frameTag != null) KeyValue('Frame tag', u.frameTag!),
                  KeyValue('Planted on', Fmt.date(u.plantedAt)),
                  KeyValue('Time since planting', Fmt.since(u.plantedAt)),
                  KeyValue('Status', Fmt.enumLabel(u.lifecycleStatus)),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Growth reports', style: t.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${updates.length} of ${_milestones.length} reports received. Field teams photograph your coral at month 1, 3 and 6.',
                style: t.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _milestones.length; i++)
                _MilestoneCard(
                  month: _milestones[i],
                  index: i + 1,
                  update: byMonth[_milestones[i]],
                  expected: u.plantedAt?.add(Duration(days: 30 * _milestones[i])),
                  isLast: i == _milestones.length - 1,
                ),
            ]),
          );
        },
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.month, required this.index, required this.update, required this.expected, required this.isLast});
  final int month;
  final int index;
  final MilestoneUpdate? update;
  final DateTime? expected;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = update;
    final done = u != null;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 28,
          child: Column(children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: done ? AppColors.primary : AppColors.mintStrong,
              child: Icon(done ? Icons.check_rounded : Icons.schedule_rounded, size: 14, color: done ? Colors.white : AppColors.textMuted),
            ),
            if (!isLast) Expanded(child: Container(width: 2, color: AppColors.mintStrong)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Panel(
              color: done ? null : AppColors.neutralBg,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('Month $month', style: t.titleMedium),
                  const SizedBox(width: 8),
                  Text('Report $index of 3', style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
                  const Spacer(),
                  if (done) StatusChip.forStatus(u.healthStatus),
                ]),
                const SizedBox(height: 4),
                Text(
                  done ? 'Verified ${Fmt.date(u.verifiedAt)}' : 'Expected around ${Fmt.date(expected)}',
                  style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                if (done) ...[
                  const SizedBox(height: 10),
                  Stack(children: [
                    NetImage(u.photoUrl, height: 170),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: Text('Month $month • ${Fmt.date(u.verifiedAt)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  KeyValue('Growth', '+${u.growthCm.toStringAsFixed(1)} cm'),
                  if (u.notes != null) Text(u.notes!, style: t.bodySmall),
                ],
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
