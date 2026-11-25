import 'package:flutter/material.dart';

import '../../models/conservation.dart';
import '../theme/app_colors.dart';
import '../utils/format.dart';

/// Small pill with icon + value, e.g. points or streak in the app bar.
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.value, required this.color, required this.bg, this.onTap, this.tooltip});

  final IconData icon;
  final String value;
  final Color color;
  final Color bg;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
          ]),
        ),
      ),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip!, child: pill);
  }
}

class PointsPill extends StatelessWidget {
  const PointsPill({super.key, required this.points, this.onTap});
  final int points;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => StatPill(
        icon: Icons.toll_rounded,
        value: Fmt.compact(points),
        color: AppColors.coin,
        bg: AppColors.coinBg,
        onTap: onTap,
        tooltip: 'BioVerse Points',
      );
}

class StreakPill extends StatelessWidget {
  const StreakPill({super.key, required this.days, this.onTap});
  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => StatPill(
        icon: Icons.local_fire_department_rounded,
        value: '$days',
        color: AppColors.streak,
        bg: AppColors.streakBg,
        onTap: onTap,
        tooltip: 'Daily streak',
      );
}

enum Tone { success, warning, danger, neutral, info }

/// Status label with color meaning (Active, Paid, Expired...).
class StatusChip extends StatelessWidget {
  const StatusChip(this.label, {super.key, this.tone = Tone.neutral});
  final String label;
  final Tone tone;

  factory StatusChip.forStatus(String status) {
    final tone = switch (status) {
      'paid' || 'active' || 'open_for_donation' || 'verified' || 'healthy' || 'planted' || 'completed' => Tone.success,
      'pending' || 'processing' || 'pending_activation' || 'paused' || 'needs_review' || 'stressed' || 'recovering' ||
      'planting' || 'monitoring' || 'pending_planting' =>
        Tone.warning,
      'failed' || 'expired' || 'cancelled' || 'rejected' || 'bleaching' || 'diseased' || 'critical' || 'dead' ||
      'deceased' =>
        Tone.danger,
      'fully_funded' => Tone.info,
      _ => Tone.neutral,
    };
    final label = status == 'open_for_donation' ? 'Active' : Fmt.enumLabel(status);
    return StatusChip(label, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      Tone.success => (AppColors.success, AppColors.successBg),
      Tone.warning => (AppColors.warning, AppColors.warningBg),
      Tone.danger => (AppColors.danger, AppColors.dangerBg),
      Tone.info => (AppColors.primary, AppColors.mint),
      Tone.neutral => (AppColors.textMuted, AppColors.neutralBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

extension EcosystemStyle on Ecosystem {
  Color get color => switch (this) {
        Ecosystem.coral => AppColors.coral,
        Ecosystem.mangrove => AppColors.mangrove,
        Ecosystem.tree => AppColors.tree,
      };

  IconData get icon => switch (this) {
        Ecosystem.coral => Icons.water_rounded,
        Ecosystem.mangrove => Icons.waves_rounded,
        Ecosystem.tree => Icons.park_rounded,
      };
}

class EcosystemTag extends StatelessWidget {
  const EcosystemTag(this.ecosystem, {super.key, this.onImage = false, this.label});
  final Ecosystem ecosystem;

  /// Solid background so the tag stays readable on top of photos.
  final bool onImage;

  /// Overrides the text (e.g. a species habitat such as "Reef").
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: onImage ? Colors.white : ecosystem.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(ecosystem.icon, size: 14, color: ecosystem.color),
        const SizedBox(width: 4),
        Text((label ?? ecosystem.label).toUpperCase(),
            style: TextStyle(color: ecosystem.color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
      ]),
    );
  }
}
