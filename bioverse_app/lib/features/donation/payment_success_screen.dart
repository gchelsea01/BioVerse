import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../models/conservation.dart';
import '../../models/donation.dart';
import 'donation_history_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.donation, this.project, this.quantity = 1});
  final Donation donation;
  final Project? project;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = donation;
    final p = project;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).popUntil((r) => r.isFirst);
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              const Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thank you, Guardian!', textAlign: TextAlign.center, style: t.headlineSmall),
              const SizedBox(height: 6),
              Text(
                p == null
                    ? 'Your donation is confirmed.'
                    : 'Your ${quantity > 1 ? '$quantity ${p.ecosystem.unitName}s' : p.ecosystem.unitName} will be planted. '
                        "We'll send photo reports at month 1, 3 and 6.",
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              Panel(
                child: Column(children: [
                  if (p != null) ...[
                    Text(p.title, style: t.titleMedium, textAlign: TextAlign.center),
                    const Divider(height: 24),
                    KeyValue('Species', p.speciesName.isEmpty ? p.ecosystem.label : p.speciesName),
                    KeyValue('Quantity', '$quantity'),
                  ],
                  KeyValue('Amount',
                      d.pointsBurned > 0 && d.netAmount == 0 ? '${Fmt.number(d.pointsBurned)} points' : Fmt.money(d.grossAmount, d.currency)),
                  if (d.pointsBurned > 0 && d.netAmount > 0) KeyValue('Points used', Fmt.number(d.pointsBurned)),
                  KeyValue('Payment date', Fmt.dateTime(d.paidAt ?? d.createdAt)),
                  KeyValue('Payment method', Fmt.enumLabel(d.paymentMethod)),
                  KeyValue('Transaction ID', d.id.length > 13 ? d.id.substring(0, 13).toUpperCase() : d.id),
                ]),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('Back to home'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DonationHistoryScreen()));
                },
                child: const Text('View my donations'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
