import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../models/donation.dart';
import '../../state/services.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  int _version = 0;

  Future<void> _act(Subscription s, String action) async {
    final donations = context.read<Services>().donations;
    if (action == 'cancel') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Cancel monthly support?'),
          content: Text('"${s.planName}" will stop charging. Units already planted keep being monitored.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep it')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Cancel support'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      switch (action) {
        case 'pause':
          await donations.pause(s.id);
        case 'resume':
          await donations.resume(s.id);
        case 'cancel':
          await donations.cancel(s.id);
      }
      if (!mounted) return;
      showMessage(context, 'Monthly support ${action == 'cancel' ? 'cancelled' : '${action}d'}.');
      setState(() => _version++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Monthly support')),
      body: AsyncView<List<Subscription>>(
        key: ValueKey(_version),
        load: () => context.read<Services>().donations.mySubscriptions(),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyState(
          title: 'No monthly support yet',
          message: 'Open any project and choose "Monthly support" to help it every month.',
          icon: Icons.autorenew_rounded,
        ),
        builder: (context, subs, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final s = subs[i];
              return Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(s.planName, style: t.titleMedium)),
                    StatusChip.forStatus(s.status),
                  ]),
                  const SizedBox(height: 8),
                  KeyValue('Billing', Fmt.enumLabel(s.interval)),
                  KeyValue('Next charge', s.status == 'active' ? Fmt.date(s.nextBillingDate) : '-'),
                  KeyValue('Started', Fmt.date(s.createdAt)),
                  const SizedBox(height: 8),
                  if (s.status == 'active' || s.status == 'paused' || s.status == 'pending_activation')
                    Row(children: [
                      if (s.status == 'active')
                        Expanded(child: OutlinedButton(onPressed: () => _act(s, 'pause'), child: const Text('Pause'))),
                      if (s.status == 'paused')
                        Expanded(child: FilledButton(onPressed: () => _act(s, 'resume'), child: const Text('Resume'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            side: const BorderSide(color: AppColors.danger, width: 1.5),
                          ),
                          onPressed: () => _act(s, 'cancel'),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ]),
                ]),
              );
            },
          ),
        ),
      ),
    );
  }
}
