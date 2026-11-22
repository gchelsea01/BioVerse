import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/conservation.dart';
import '../../services/donation_service.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import 'payment_screen.dart';
import 'payment_success_screen.dart';

const _banks = ['BCA', 'BRI', 'BNI', 'MANDIRI', 'PERMATA'];

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.project, required this.quantity});
  final Project project;
  final int quantity;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PayMethod _method = PayMethod.qris;
  String _bank = _banks.first;
  bool _anonymous = false;
  bool _loading = false;
  final _nickname = TextEditingController();

  Project get p => widget.project;
  int get _pointsNeeded => p.pricePerUnitPoints * widget.quantity;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final session = context.read<Session>();
    setState(() => _loading = true);
    try {
      final donation = await context.read<Services>().donations.checkout(
            project: p,
            quantity: widget.quantity,
            method: _method,
            bankCode: _bank,
            nickname: _nickname.text,
            petId: session.pet?.id,
            anonymous: _anonymous,
          );
      if (!mounted) return;
      final next = donation.isPaid
          ? PaymentSuccessScreen(donation: donation, project: p, quantity: widget.quantity)
          : PaymentScreen(donation: donation, project: p, quantity: widget.quantity);
      if (donation.isPaid) session.refreshUser();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => next));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final points = context.watch<Session>().points;
    final enoughPoints = points >= _pointsNeeded && _pointsNeeded > 0;
    final total = p.pricePerUnit * widget.quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                NetImage(p.imageUrl, height: 64, width: 64, icon: p.ecosystem.icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    EcosystemTag(p.ecosystem),
                    const SizedBox(height: 4),
                    Text(p.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ]),
                ),
              ]),
              const Divider(height: 24),
              KeyValue('Species', p.speciesName.isEmpty ? p.ecosystem.label : p.speciesName),
              KeyValue('Quantity', '${widget.quantity} ${p.ecosystem.unitName}${widget.quantity > 1 ? 's' : ''}'),
              const KeyValue('Donation type', 'One-time'),
              KeyValue('Total', _method == PayMethod.points ? '${Fmt.number(_pointsNeeded)} points' : Fmt.money(total, p.currency),
                  bold: true),
            ]),
          ),
          const SizedBox(height: 20),
          Text('Payment method', style: t.titleLarge),
          const SizedBox(height: 10),
          _MethodTile(
            method: PayMethod.qris,
            selected: _method,
            subtitle: 'Scan with any banking or e-wallet app',
            icon: Icons.qr_code_2_rounded,
            onTap: () => setState(() => _method = PayMethod.qris),
          ),
          _MethodTile(
            method: PayMethod.virtualAccount,
            selected: _method,
            subtitle: 'Transfer from BCA, BRI, BNI, Mandiri, or Permata',
            icon: Icons.account_balance_rounded,
            onTap: () => setState(() => _method = PayMethod.virtualAccount),
          ),
          if (_method == PayMethod.virtualAccount)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final b in _banks)
                  ChoiceChip(
                    label: Text(b),
                    selected: _bank == b,
                    onSelected: (_) => setState(() => _bank = b),
                    labelStyle: TextStyle(color: _bank == b ? Colors.white : AppColors.navy, fontWeight: FontWeight.w700),
                  ),
              ]),
            ),
          _MethodTile(
            method: PayMethod.ewallet,
            selected: _method,
            subtitle: 'OVO, DANA, ShopeePay, and more',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () => setState(() => _method = PayMethod.ewallet),
          ),
          _MethodTile(
            method: PayMethod.points,
            selected: _method,
            subtitle: enoughPoints
                ? 'You have ${Fmt.number(points)} points'
                : 'Needs ${Fmt.number(_pointsNeeded)} points, you have ${Fmt.number(points)}',
            icon: Icons.toll_rounded,
            enabled: enoughPoints,
            onTap: () => setState(() => _method = PayMethod.points),
          ),
          if (_method == PayMethod.points)
            Panel(
              color: AppColors.coinBg,
              child: Column(children: [
                KeyValue('Available points', Fmt.number(points)),
                KeyValue('Points required', Fmt.number(_pointsNeeded)),
                KeyValue('Remaining after donation', Fmt.number(points - _pointsNeeded), bold: true),
              ]),
            ),
          const SizedBox(height: 16),
          if (p.ecosystem == Ecosystem.coral)
            TextField(
              controller: _nickname,
              decoration: const InputDecoration(
                labelText: 'Name your coral (optional)',
                hintText: 'e.g. Bubbles',
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _anonymous,
            onChanged: (v) => setState(() => _anonymous = v),
            title: const Text('Donate anonymously'),
            subtitle: const Text('Hide your name on the supporter ranking'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LoadingButton(
            label: _method == PayMethod.points ? 'Confirm donation' : 'Pay ${Fmt.money(total, p.currency)}',
            loading: _loading,
            onPressed: (_method == PayMethod.points && !enoughPoints) ? null : _pay,
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final PayMethod method;
  final PayMethod selected;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isSelected = method == selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? AppColors.mint : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1),
        ),
        child: ListTile(
          enabled: enabled,
          onTap: enabled ? onTap : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(icon, color: enabled ? AppColors.primary : AppColors.textMuted),
          title: Text(method.label, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
