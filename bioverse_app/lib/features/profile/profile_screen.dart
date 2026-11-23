import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../models/user.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import '../donation/donation_history_screen.dart';
import '../donation/subscriptions_screen.dart';
import '../pet/shop_screen.dart';
import 'edit_profile_screen.dart';
import 'leaderboard_screen.dart';
import 'notifications_screen.dart';
import 'profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in anytime with your email and password.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<Session>().logout();
  }

  void _push(BuildContext context, Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final session = context.watch<Session>();
    final user = session.user;
    final services = context.read<Services>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        Panel(
          color: AppColors.mint,
          child: Row(children: [
            ProfileAvatar(user: user, radius: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.fullName ?? '-', style: t.titleLarge),
                Text(user?.email ?? '', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                if (user?.referralCode != null)
                  Text('Referral code: ${user!.referralCode}', style: t.labelSmall?.copyWith(color: AppColors.primary)),
              ]),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 14)),
              onPressed: () => _push(context, const EditProfileScreen()),
              child: const Text('Edit'),
            ),
          ]),
        ),
        const SectionHeader('Activity'),
        AsyncView<UserStats>(
          load: () => services.user.stats(),
          builder: (_, stats, _) => Column(children: [
            Row(children: [
              Expanded(child: _Stat(icon: Icons.eco_rounded, value: Fmt.compact(stats.unitsAdopted), label: 'Units adopted')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(icon: Icons.flag_rounded, value: '${stats.missionsCompleted}', label: 'Missions done')),
              const SizedBox(width: 8),
              Expanded(child: _Stat(icon: Icons.toll_rounded, value: Fmt.compact(stats.points), label: 'Points')),
            ]),
            const SizedBox(height: 8),
            Panel(
              child: Row(children: [
                const Icon(Icons.volunteer_activism_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text('Total donated', style: Theme.of(context).textTheme.titleSmall)),
                Text(
                  Fmt.money(stats.totalIn(user?.currency ?? 'IDR'), user?.currency ?? 'IDR'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Panel(
              color: AppColors.streakBg,
              child: Row(children: [
                const Icon(Icons.local_fire_department_rounded, color: AppColors.streak),
                const SizedBox(width: 10),
                Expanded(child: Text('Streak: ${stats.currentStreak} days', style: Theme.of(context).textTheme.titleSmall)),
                Text('Best ${stats.longestStreak}', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ]),
        ),
        const SectionHeader('Account'),
        Card(
          child: Column(children: [
            _MenuItem(icon: Icons.receipt_long_rounded, label: 'My donations & growth reports', onTap: () => _push(context, const DonationHistoryScreen())),
            _MenuItem(icon: Icons.autorenew_rounded, label: 'Monthly support', onTap: () => _push(context, const SubscriptionsScreen())),
            _MenuItem(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => _push(context, const NotificationsScreen())),
            _MenuItem(icon: Icons.storefront_rounded, label: 'Pet shop & items', onTap: () => _push(context, const ShopScreen())),
            _MenuItem(icon: Icons.emoji_events_outlined, label: 'Top supporters', onTap: () => _push(context, const LeaderboardScreen())),
            _MenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & support',
              last: true,
              onTap: () => showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Help & support'),
                  content: const Text(
                    'Questions about a donation or your pet? Email support@bioverse.id and include your transaction ID if it is about a payment.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.danger,
            side: const BorderSide(color: AppColors.danger, width: 1.5),
          ),
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log out'),
        ),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 6),
        Text(value, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(label, textAlign: TextAlign.center, style: t.labelSmall?.copyWith(color: AppColors.textMuted)),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.last = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
      if (!last) const Divider(indent: 64),
    ]);
  }
}
