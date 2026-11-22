import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../models/conservation.dart';
import '../../models/donation.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import 'payment_success_screen.dart';

/// Shows QRIS / VA / e-wallet instructions and polls until the webhook marks
/// the donation as paid.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.donation, this.project, this.quantity = 1});
  final Donation donation;
  final Project? project;
  final int quantity;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Donation _donation = widget.donation;
  Timer? _poll;
  Timer? _tick;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 6), (_) => _check(silent: true));
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _poll?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    _checking = true;
    if (!silent) setState(() {});
    try {
      final d = await context.read<Services>().donations.detail(_donation.id);
      if (!mounted) return;
      setState(() => _donation = d);
      if (d.isPaid) {
        _poll?.cancel();
        context.read<Session>()
          ..refreshUser()
          ..refreshPet();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaymentSuccessScreen(donation: d, project: widget.project, quantity: widget.quantity)),
        );
      } else if (!d.isPending) {
        _poll?.cancel();
      } else if (!silent) {
        showMessage(context, 'Payment not received yet. It can take a minute after you pay.');
      }
    } catch (e) {
      if (mounted && !silent) showError(context, e);
    } finally {
      _checking = false;
      if (mounted && !silent) setState(() {});
    }
  }

  String _countdown() {
    final exp = _donation.expiredAt;
    if (exp == null) return '';
    final left = exp.difference(DateTime.now());
    if (left.isNegative) return 'Expired';
    final h = left.inHours;
    final m = left.inMinutes % 60;
    final s = left.inSeconds % 60;
    return '${h > 0 ? '${h}h ' : ''}${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final d = _donation;
    final pay = d.payment;
    final amount = Fmt.money(d.settlementAmount > 0 ? d.settlementAmount : d.netAmount,
        d.settlementAmount > 0 ? d.settlementCurrency : d.currency);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Panel(
            color: AppColors.mint,
            child: Column(children: [
              Text('Amount to pay', style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(amount, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy)),
              if (d.settlementCurrency != d.currency)
                Text('${Fmt.money(d.netAmount, d.currency)} converted to ${d.settlementCurrency}',
                    style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                StatusChip.forStatus(d.status),
                if (d.isPending && d.expiredAt != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('Pay within ${_countdown()}', style: t.labelMedium),
                ],
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          if (pay?.qrString != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: QrImageView(data: pay!.qrString!, size: 220),
              ),
            ),
            const SizedBox(height: 16),
            const _Steps(steps: [
              'Open your mobile banking or e-wallet app.',
              'Choose "Scan QR" / QRIS.',
              'Scan the code above and check the amount.',
              'Confirm the payment. This page updates automatically.',
            ]),
          ],
          if (pay?.vaNumber != null) ...[
            Panel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${pay!.bankCode ?? 'Bank'} Virtual Account', style: t.labelLarge?.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: SelectableText(pay.vaNumber!, style: t.headlineSmall?.copyWith(letterSpacing: 1.5))),
                  IconButton.filledTonal(
                    tooltip: 'Copy number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: pay.vaNumber!));
                      showMessage(context, 'Virtual account number copied');
                    },
                    icon: const Icon(Icons.copy_rounded),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            _Steps(steps: [
              'Open ${pay.bankCode ?? 'your bank'} mobile banking or ATM.',
              'Choose Transfer → Virtual Account.',
              'Enter the number above and confirm the amount.',
              'This page updates automatically after payment.',
            ]),
          ],
          if (pay?.paymentUrl != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(pay!.paymentUrl!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open payment page'),
            ),
          ],
          if (pay == null || (pay.qrString == null && pay.vaNumber == null && pay.paymentUrl == null))
            const Panel(child: Text('Payment instructions are being prepared. Tap "Check payment status" in a moment.')),
          if (!d.isPending && !d.isPaid) ...[
            const SizedBox(height: 16),
            Panel(
              color: AppColors.dangerBg,
              child: Text('This payment is ${d.status}. Please start a new donation.', style: t.bodyMedium),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: d.isPending
              ? LoadingButton(label: "I've paid – check status", loading: _checking, onPressed: () => _check())
              : FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Back to home'),
                ),
        ),
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How to pay', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              Expanded(child: Text(steps[i], style: t.bodyMedium)),
            ]),
          ),
      ]),
    );
  }
}
