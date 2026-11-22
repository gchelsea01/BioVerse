import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import 'auth_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _form = GlobalKey<FormState>();
  final _token = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _token.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<Services>().auth.verifyEmail(_token.text);
      if (!mounted) return;
      await context.read<Session>().refreshUser();
      if (!mounted) return;
      showMessage(context, 'Email verified. Thank you!');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<Session>().user?.email ?? 'your email';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Icon(Icons.mark_email_read_rounded, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'We sent a verification code to $email. Paste it below to secure your account.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            LabeledField(
              label: 'Verification code',
              controller: _token,
              textInputAction: TextInputAction.done,
              validator: (v) => Validators.required(v, 'Code'),
              onSubmitted: (_) => _submit(),
            ),
            LoadingButton(label: 'Verify', loading: _loading, onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}
