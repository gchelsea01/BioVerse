import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/conservation.dart';
import 'project_detail_screen.dart';

void openProject(BuildContext context, Project project) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)));

/// List card: image left, info right, full-width "Donate" button so the
/// action is obvious (Figma used a faint "See Detail" button).
class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = project;
    return Panel(
      padding: EdgeInsets.zero,
      onTap: () => openProject(context, p),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(children: [
          NetImage(p.imageUrl, height: 140, radius: 0, icon: p.ecosystem.icon),
          Positioned(left: 12, top: 12, child: EcosystemTag(p.ecosystem)),
          Positioned(right: 12, top: 12, child: StatusChip.forStatus(p.status)),
          if (p.isUrgent)
            Positioned(
              left: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
                child: const Text('URGENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
              ),
            ),
        ]),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (p.locationName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(children: [
                  const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(p.locationName!,
                        style: t.labelMedium?.copyWith(color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            const SizedBox(height: 4),
            Text(p.description, style: t.bodySmall?.copyWith(color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Progress(p.progress, color: p.ecosystem.color),
            const SizedBox(height: 6),
            Row(children: [
              Text('${Fmt.number(p.fundedUnits)} of ${Fmt.number(p.targetUnits)} ${p.ecosystem.unitName}s',
                  style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${Fmt.money(p.pricePerUnit, p.currency)} / unit', style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

/// Compact horizontal card for the home carousel.
class ProjectMiniCard extends StatelessWidget {
  const ProjectMiniCard({super.key, required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = project;
    return SizedBox(
      width: 240,
      child: Panel(
        padding: EdgeInsets.zero,
        onTap: () => openProject(context, p),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetImage(p.imageUrl, height: 110, width: 240, radius: 0, icon: p.ecosystem.icon),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EcosystemTag(p.ecosystem),
              const SizedBox(height: 6),
              Text(p.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Progress(p.progress, color: p.ecosystem.color, height: 6),
              const SizedBox(height: 4),
              Text(
                '${(p.progress * 100).round()}% funded${p.locationName != null ? ' • ${p.locationName}' : ''}',
                style: t.labelSmall?.copyWith(color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
