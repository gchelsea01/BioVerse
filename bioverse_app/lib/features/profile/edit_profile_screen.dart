import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../models/user.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import '../auth/auth_widgets.dart';
import 'profile_avatar.dart';

const _genders = {
  'male': 'Male',
  'female': 'Female',
  'other': 'Other',
  'prefer_not_to_say': 'Prefer not to say',
};

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _user?.fullName);
  late final _phone = TextEditingController(text: _user?.phoneNumber);
  late String? _gender = _user?.gender;
  late String? _dob = _user?.dateOfBirth;
  late String _currency = _user?.currency ?? 'IDR';
  File? _avatar;
  bool _loading = false;

  UserProfile? get _user => context.read<Session>().user;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file != null) setState(() => _avatar = File(file.path));
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dob ?? '') ?? DateTime(2003);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final services = context.read<Services>();
    final session = context.read<Session>();
    setState(() => _loading = true);
    try {
      String? avatarKey;
      if (_avatar != null) avatarKey = await services.user.upload(_avatar!, purpose: 'avatar');
      final updated = await services.user.update(
        fullName: _name.text,
        phoneNumber: _phone.text,
        gender: _gender,
        dateOfBirth: _dob,
        currency: _currency,
        avatarObjectKey: avatarKey,
      );
      session.setUser(updated);
      if (!mounted) return;
      showMessage(context, 'Profile saved');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
          Center(
            child: Stack(children: [
              _avatar != null
                  ? CircleAvatar(radius: 48, backgroundImage: FileImage(_avatar!))
                  : ProfileAvatar(user: user, radius: 48),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  tooltip: 'Change photo',
                  onPressed: _pickAvatar,
                  style: IconButton.styleFrom(backgroundColor: AppColors.navy),
                  icon: const Icon(Icons.photo_camera_rounded, size: 18),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          LabeledField(label: 'Full name', controller: _name, validator: (v) => Validators.required(v, 'Name')),
          LabeledField(label: 'Phone number', controller: _phone, hint: '+62…', keyboardType: TextInputType.phone),
          Text('Email', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextFormField(initialValue: user?.email, enabled: false),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: [for (final e in _genders.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDob,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Date of birth', suffixIcon: Icon(Icons.calendar_today_rounded)),
              child: Text(_dob ?? 'Not set'),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: const InputDecoration(labelText: 'Preferred currency'),
            items: const [
              DropdownMenuItem(value: 'IDR', child: Text('IDR – Indonesian Rupiah')),
              DropdownMenuItem(value: 'USD', child: Text('USD – US Dollar')),
            ],
            onChanged: (v) => setState(() => _currency = v ?? 'IDR'),
          ),
          const SizedBox(height: 24),
          LoadingButton(label: 'Save changes', loading: _loading, onPressed: _save),
        ]),
      ),
    );
  }
}
