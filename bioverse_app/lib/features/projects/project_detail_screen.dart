import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/conservation.dart';
import '../donation/checkout_screen.dart';
import '../donation/subscription_setup_screen.dart';

enum GiveMode { once, monthly }

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.project});
  final Project project;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  GiveMode _mode = GiveMode.once;
  int _qty = 1;

  Project get p => widget.project;

  void _continue() {
    final route = _mode == GiveMode.once
        ? MaterialPageRoute(builder: (_) => CheckoutScreen(project: p, quantity: _qty))
        : MaterialPageRoute(builder: (_) => SubscriptionSetupScreen(project: p, quantity: _qty));
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = p.pricePerUnit * _qty;
    return Scaffold(
      appBar: AppBar(title: Text(p.title, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          NetImage(p.imageUrl, height: 200, icon: p.ecosystem.icon),
          const SizedBox(height: 16),
          Row(children: [EcosystemTag(p.ecosystem), const SizedBox(width: 8), StatusChip.forStatus(p.status)]),
          const SizedBox(height: 10),
          Text(p.title, style: t.headlineSmall),
          const SizedBox(height: 8),
          Text(p.description, style: t.bodyMedium?.copyWith(height: 1.45)),
          const SizedBox(height: 16),
          Panel(
            color: AppColors.mint,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Donation progress', style: t.titleMedium),
              const SizedBox(height: 10),
              Progress(p.progress, color: p.ecosystem.color, height: 10),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: InfoTile(label: 'Funded', value: '${Fmt.number(p.fundedUnits)} / ${Fmt.number(p.targetUnits)}')),
                const SizedBox(width: 8),
                Expanded(child: InfoTile(label: 'Already planted', value: Fmt.number(p.plantedUnits))),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          InfoTile(icon: Icons.event_rounded, label: 'Donation period', value: '${Fmt.date(p.startDate)} – ${Fmt.date(p.endDate)}'),
          const SizedBox(height: 8),
          InfoTile(icon: Icons.spa_rounded, label: 'Estimated planting date', value: Fmt.date(p.plantingDate)),
          const SizedBox(height: 8),
          InfoTile(icon: p.ecosystem.icon, label: 'Species', value: p.speciesName.isEmpty ? p.ecosystem.label : p.speciesName),
          const SizedBox(height: 8),
          InfoTile(icon: Icons.monitor_heart_rounded, label: 'Site health', value: Fmt.enumLabel(p.healthStatus)),
          if (p.objectives.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Goals', style: t.titleMedium),
            const SizedBox(height: 6),
            Text(p.objectives, style: t.bodyMedium?.copyWith(height: 1.45)),
          ],
          const SizedBox(height: 24),
          if (p.isOpen) ...[
            Text('How would you like to give?', style: t.titleLarge),
            const SizedBox(height: 10),
            _ModeOption(
              selected: _mode == GiveMode.once,
              icon: Icons.favorite_rounded,
              title: 'One-time donation',
              body: 'Pay once. Your ${p.ecosystem.unitName}s are planted and you get photo reports at month 1, 3 and 6.',
              onTap: () => setState(() => _mode = GiveMode.once),
            ),
            const SizedBox(height: 8),
            _ModeOption(
              selected: _mode == GiveMode.monthly,
              icon: Icons.autorenew_rounded,
              title: 'Monthly support',
              body: 'Charged automatically every month to keep your units maintained. Pause or cancel anytime from Profile.',
              onTap: () => setState(() => _mode = GiveMode.monthly),
            ),
            const SizedBox(height: 16),
            Panel(
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Number of ${p.ecosystem.unitName}s', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${Fmt.money(p.pricePerUnit, p.currency)} each', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                    ]),
                  ),
                  _Stepper(
                    value: _qty,
                    max: p.remainingUnits == 0 ? 1 : p.remainingUnits.clamp(1, 100),
                    onChanged: (v) => setState(() => _qty = v),
                  ),
                ]),
                const Divider(height: 24),
                KeyValue(_mode == GiveMode.once ? 'Total' : 'Unit cost per month', Fmt.money(total, p.currency), bold: true),
              ]),
            ),
          ] else
            Panel(
              color: AppColors.neutralBg,
              child: Text(
                'This project is ${Fmt.enumLabel(p.status).toLowerCase()} and no longer accepts donations. '
                'You can still follow its progress.',
                style: t.bodyMedium,
              ),
            ),
        ],
      ),
      bottomNavigationBar: p.isOpen
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton(
                  onPressed: _continue,
                  child: Text(_mode == GiveMode.once ? 'Continue to payment' : 'Set up monthly support'),
                ),
              ),
            )
          : null,
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.selected, required this.icon, required this.title, required this.body, required this.onTap});
  final bool selected;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: selected ? AppColors.mint : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 4),
                Text(body, style: t.bodySmall?.copyWith(color: AppColors.textMuted, height: 1.4)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.max, required this.onChanged});
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, VoidCallback? onTap, String tip) => IconButton.filled(
          tooltip: tip,
          onPressed: onTap,
          style: IconButton.styleFrom(
            backgroundColor: AppColors.navy,
            disabledBackgroundColor: AppColors.mintStrong,
            foregroundColor: Colors.white,
          ),
          icon: Icon(icon),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      btn(Icons.remove_rounded, value > 1 ? () => onChanged(value - 1) : null, 'Fewer'),
      SizedBox(
        width: 44,
        child: Text('$value', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
      ),
      btn(Icons.add_rounded, value < max ? () => onChanged(value + 1) : null, 'More'),
    ]);
  }
}
