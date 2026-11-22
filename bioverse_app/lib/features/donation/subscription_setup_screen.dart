import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../models/conservation.dart';
import '../../models/donation.dart';
import '../../services/donation_service.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import 'subscriptions_screen.dart';

/// Monthly support flow. Usability testing found the old flow confusing, so
/// the screen states up front what happens, when you pay, and how to stop.
class SubscriptionSetupScreen extends StatefulWidget {
  const SubscriptionSetupScreen({super.key, required this.project, required this.quantity});
  final Project project;
  final int quantity;

  @override
  State<SubscriptionSetupScreen> createState() => _SubscriptionSetupScreenState();
}

class _SubscriptionSetupScreenState extends State<SubscriptionSetupScreen> {
  String? _planId;
  PayMethod _method = PayMethod.ewallet;
  bool _loading = false;

  Future<void> _subscribe() async {
    final planId = _planId;
    if (planId == null) return;
    setState(() => _loading = true);
    try {
      final sub = await context.read<Services>().donations.subscribe(
            planId: planId,
            projectId: widget.project.id,
            quantity: widget.quantity,
            method: _method,
          );
      if (!mounted) return;
      if (sub.authorizationUrl != null) {
        await launchUrl(Uri.parse(sub.authorizationUrl!), mode: LaunchMode.externalApplication);
      }
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _SubscribedScreen(subscription: sub)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final currency = context.watch<Session>().user?.currency ?? 'IDR';
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly support')),
      body: AsyncView<List<SubscriptionPlan>>(
        load: () => context.read<Services>().donations.plans(),
        isEmpty: (plans) => plans.isEmpty,
        empty: const EmptyState(
          title: 'Monthly plans are not available yet',
          message: 'You can still make a one-time donation.',
          icon: Icons.autorenew_rounded,
        ),
        builder: (context, plans, _) {
          _planId ??= plans.first.id;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const _HowItWorks(),
              const SizedBox(height: 20),
              Text('Choose a plan', style: t.titleLarge),
              const SizedBox(height: 10),
              for (final plan in plans) ...[
                _PlanTile(
                  plan: plan,
                  currency: currency,
                  selected: plan.id == _planId,
                  onTap: () => setState(() => _planId = plan.id),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 12),
              Panel(
                child: Column(children: [
                  KeyValue('Project', widget.project.title),
                  KeyValue('Units supported', '${widget.quantity} ${widget.project.ecosystem.unitName}${widget.quantity > 1 ? 's' : ''}'),
                ]),
              ),
              const SizedBox(height: 20),
              Text('Pay with', style: t.titleLarge),
              const SizedBox(height: 8),
              SegmentedButton<PayMethod>(
                segments: const [
                  ButtonSegment(value: PayMethod.ewallet, label: Text('E-Wallet'), icon: Icon(Icons.account_balance_wallet_rounded)),
                  ButtonSegment(value: PayMethod.virtualAccount, label: Text('Bank'), icon: Icon(Icons.account_balance_rounded)),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                "You'll be taken to the payment provider to approve recurring charges. Nothing is charged until you approve.",
                style: t.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LoadingButton(label: 'Start monthly support', loading: _loading, onPressed: _planId == null ? null : _subscribe),
        ),
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget step(int n, String title, String body) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: AppColors.primary,
              child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(body, style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
              ]),
            ),
          ]),
        );
    return Panel(
      color: AppColors.mint,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('How monthly support works', style: t.titleMedium),
        const SizedBox(height: 6),
        step(1, 'Pick a plan', 'Choose how often you are charged.'),
        step(2, 'Approve once', 'Confirm the recurring payment in your e-wallet or bank.'),
        step(3, 'We charge automatically', 'Each period funds care and monitoring for your units.'),
        step(4, 'Stay in control', 'Pause, resume, or cancel anytime in Profile → Monthly support.'),
      ]),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.plan, required this.currency, required this.selected, required this.onTap});
  final SubscriptionPlan plan;
  final String currency;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final price = priceIn(plan.prices, currency);
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
                Text(plan.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                if (plan.benefits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(plan.benefits.map(Fmt.enumLabel).join(' • '),
                        style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ),
              ]),
            ),
            if (price != null)
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(Fmt.money(price.amount, price.currency), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                Text('/ ${plan.interval.replaceAll('ly', '')}', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _SubscribedScreen extends StatelessWidget {
  const _SubscribedScreen({required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = subscription;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 24),
          const Center(
            child: CircleAvatar(radius: 40, backgroundColor: AppColors.primary, child: Icon(Icons.autorenew_rounded, color: Colors.white, size: 44)),
          ),
          const SizedBox(height: 16),
          Text('Monthly support created', textAlign: TextAlign.center, style: t.headlineSmall),
          const SizedBox(height: 8),
          Text(
            s.status == 'active'
                ? 'You are all set. Thank you for caring for nature every month.'
                : 'Finish approving the recurring payment in the provider page. The status becomes Active once approved.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Panel(
            child: Column(children: [
              KeyValue('Plan', s.planName),
              KeyValue('Status', Fmt.enumLabel(s.status)),
              KeyValue('Billing', Fmt.enumLabel(s.interval)),
              KeyValue('Next charge', Fmt.date(s.nextBillingDate)),
            ]),
          ),
          const SizedBox(height: 24),
          if (s.authorizationUrl != null && s.status != 'active') ...[
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(s.authorizationUrl!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open approval page again'),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton(
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionsScreen()));
            },
            child: const Text('Manage monthly support'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to home')),
        ]),
      ),
    );
  }
}
