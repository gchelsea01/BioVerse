import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/conservation.dart';
import '../../models/donation.dart';
import '../../models/json.dart';
import '../../state/services.dart';
import 'adopted_unit_screen.dart';
import 'payment_screen.dart';

/// Two tabs: what you adopted (with growth reports) and every transaction.
class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My donations'),
          bottom: const TabBar(
            labelColor: AppColors.navy,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [Tab(text: 'Adopted & growth'), Tab(text: 'Transactions')],
          ),
        ),
        body: const TabBarView(children: [_AdoptedTab(), _TransactionsTab()]),
      ),
    );
  }
}

class _AdoptedTab extends StatelessWidget {
  const _AdoptedTab();

  @override
  Widget build(BuildContext context) {
    return AsyncView<Paged<AdoptedUnit>>(
      load: () => context.read<Services>().conservation.myUnits(),
      isEmpty: (p) => p.items.isEmpty,
      empty: const EmptyState(
        title: 'Nothing adopted yet',
        message: 'After your donation is paid, every coral, mangrove, and tree you adopt shows up here with its photo reports.',
        icon: Icons.eco_rounded,
      ),
      builder: (context, page, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: page.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _AdoptedCard(unit: page.items[i]),
        ),
      ),
    );
  }
}

class _AdoptedCard extends StatelessWidget {
  const _AdoptedCard({required this.unit});
  final AdoptedUnit unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = unit;
    return Panel(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdoptedUnitScreen(unit: u))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Stack(children: [
          NetImage(u.latestPhotoUrl, height: 130, radius: 0, icon: u.ecosystem.icon),
          Positioned(left: 12, top: 12, child: EcosystemTag(u.ecosystem)),
        ]),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(u.nickname ?? u.projectName, style: t.titleMedium)),
              StatusChip.forStatus(u.lifecycleStatus),
            ]),
            if (u.nickname != null) Text(u.projectName, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
            if (u.locationName != null)
              Row(children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 2),
                Expanded(child: Text(u.locationName!, style: t.bodySmall?.copyWith(color: AppColors.textMuted))),
              ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: InfoTile(label: 'Species', value: u.speciesName)),
              const SizedBox(width: 8),
              Expanded(
                child: InfoTile(
                  label: u.quantity > 1 ? 'Units' : 'Unit code',
                  value: u.quantity > 1 ? '${u.quantity} ${u.ecosystem.unitName}s' : u.code,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Time since planting', style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
                    Text(Fmt.since(u.plantedAt), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ),
                const Text('Growth reports', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TransactionsTab extends StatefulWidget {
  const _TransactionsTab();

  @override
  State<_TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<_TransactionsTab> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          for (final (value, label) in [(null, 'All'), ('paid', 'Paid'), ('pending', 'Pending'), ('expired', 'Expired')])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: _status == value,
                onSelected: (_) => setState(() => _status = value),
                labelStyle: TextStyle(color: _status == value ? Colors.white : AppColors.navy, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
      Expanded(
        child: AsyncView<Paged<Donation>>(
          key: ValueKey(_status),
          load: () => context.read<Services>().donations.history(status: _status),
          isEmpty: (p) => p.items.isEmpty,
          empty: const EmptyState(title: 'No transactions yet', icon: Icons.receipt_long_rounded),
          builder: (context, page, reload) => RefreshIndicator(
            onRefresh: reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final d = page.items[i];
                final amount = d.pointsBurned > 0 && d.netAmount == 0
                    ? '${Fmt.number(d.pointsBurned)} pts'
                    : Fmt.money(d.grossAmount, d.currency);
                return Panel(
                  onTap: () => d.isPending
                      ? Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(donation: d)))
                      : _showReceipt(context, d),
                  child: Row(children: [
                    if (d.imageUrl != null)
                      NetImage(d.imageUrl, width: 48, height: 48, icon: _icon(d))
                    else
                      CircleAvatar(backgroundColor: AppColors.mint, child: Icon(_icon(d), color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d.projectTitle ?? d.typeLabel,
                            style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(
                          [
                            if (d.quantity > 0) '${d.quantity} unit${d.quantity > 1 ? 's' : ''}',
                            Fmt.date(d.createdAt),
                            Fmt.enumLabel(d.paymentMethod),
                          ].join(' • '),
                          style: t.bodySmall?.copyWith(color: AppColors.textMuted),
                        ),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(amount, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      StatusChip.forStatus(d.status),
                    ]),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }

  IconData _icon(Donation d) =>
      (Ecosystem.fromDonationType(d.type) ?? (d.projectCategory != null ? Ecosystem.parse(d.projectCategory) : Ecosystem.coral)).icon;

  void _showReceipt(BuildContext context, Donation d) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Donation receipt', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (d.projectTitle != null) KeyValue('Project', d.projectTitle!),
            if (d.locationName != null) KeyValue('Location', d.locationName!),
            if (d.quantity > 0) KeyValue('Units', '${d.quantity}'),
            KeyValue('Type', d.typeLabel),
            KeyValue('Status', Fmt.enumLabel(d.status)),
            KeyValue('Amount', Fmt.money(d.grossAmount, d.currency)),
            if (d.settlementCurrency != d.currency) KeyValue('Charged', Fmt.money(d.settlementAmount, d.settlementCurrency)),
            if (d.pointsBurned > 0) KeyValue('Points used', Fmt.number(d.pointsBurned)),
            KeyValue('Method', Fmt.enumLabel(d.paymentMethod)),
            KeyValue('Created', Fmt.dateTime(d.createdAt)),
            if (d.paidAt != null) KeyValue('Paid', Fmt.dateTime(d.paidAt)),
            KeyValue('Transaction ID', d.id),
          ]),
        ),
      ),
    );
  }
}
