import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../state/session.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _referral = TextEditingController();
  bool _agreed = false;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _referral]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      showMessage(context, 'Please agree to the Terms of Service and Privacy Policy.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<Session>().register(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
            referral: _referral.text,
          );
      // Root gate switches to the app; drop the auth stack.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _form,
            child: AutofillGroup(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const AuthHeader(
                  title: 'Join the Guardians',
                  subtitle: 'Create your account and start restoring reefs, mangroves, and forests.',
                ),
                LabeledField(
                  label: 'Full name',
                  controller: _name,
                  hint: 'Maya Rivera',
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                LabeledField(
                  label: 'Email address',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                PasswordField(label: 'Password', controller: _password, isNew: true),
                PasswordField(
                  label: 'Confirm password',
                  controller: _confirm,
                  isNew: true,
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                LabeledField(
                  label: 'Referral code (optional)',
                  controller: _referral,
                  hint: 'e.g. REEF2026',
                  textInputAction: TextInputAction.done,
                ),
                CheckboxListTile(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.primary,
                  title: const Text('I agree to the Terms of Service and Privacy Policy.'),
                ),
                const SizedBox(height: 12),
                LoadingButton(label: 'Create account', loading: _loading, onPressed: _submit),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Already have an account?', style: TextStyle(color: AppColors.textMuted)),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Log in')),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
