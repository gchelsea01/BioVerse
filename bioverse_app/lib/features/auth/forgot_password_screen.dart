import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../state/services.dart';
import 'auth_widgets.dart';

/// Two steps on one screen: request the email, then paste the token and set
/// a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _token = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _token.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<Services>().auth;
    setState(() => _loading = true);
    try {
      if (!_sent) {
        await auth.forgotPassword(_email.text);
        if (!mounted) return;
        setState(() => _sent = true);
        showMessage(context, 'If that email is registered, a reset code is on its way.');
      } else {
        await auth.resetPassword(_token.text, _password.text);
        if (!mounted) return;
        showMessage(context, 'Password updated. Please log in.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              _sent
                  ? 'Check your inbox for the reset code, then choose a new password.'
                  : 'Enter your account email. We will send you a code to reset your password.',
              style: t.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            LabeledField(
              label: 'Email address',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            if (_sent) ...[
              LabeledField(
                label: 'Reset code',
                controller: _token,
                validator: (v) => Validators.required(v, 'Code'),
              ),
              PasswordField(label: 'New password', controller: _password, isNew: true, onSubmitted: (_) => _submit()),
            ],
            const SizedBox(height: 8),
            LoadingButton(label: _sent ? 'Save new password' : 'Send reset code', loading: _loading, onPressed: _submit),
            if (_sent)
              TextButton(onPressed: () => setState(() => _sent = false), child: const Text('Use a different email')),
          ]),
        ),
      ),
    );
  }
}
