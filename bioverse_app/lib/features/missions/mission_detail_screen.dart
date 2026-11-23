import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/gamification.dart';
import '../../state/services.dart';
import '../../state/session.dart';
import 'mission_tile.dart';
import 'submission_status_screen.dart';

/// Mission brief → take/choose a proof photo → upload → submit.
class MissionDetailScreen extends StatefulWidget {
  const MissionDetailScreen({super.key, required this.mission});
  final EcoMission mission;

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  File? _photo;
  bool _loading = false;

  EcoMission get m => widget.mission;

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 82);
      if (file != null) setState(() => _photo = File(file.path));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(c, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _submit() async {
    final photo = _photo;
    if (photo == null) return;
    final services = context.read<Services>();
    final petId = context.read<Session>().pet?.id;
    setState(() => _loading = true);
    try {
      final key = await services.user.upload(photo, purpose: 'mission_proof');
      final receipt = await services.game.submitMission(m.id, key, petId: petId);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SubmissionStatusScreen(mission: m, submission: receipt)),
      );
    } catch (e) {
      if (!mounted) return;
      final err = ApiException.from(e);
      // The photo check runs on a separate service; a 5xx here usually means
      // that service is down, not that the user did something wrong.
      showError(
        context,
        (err.statusCode ?? 0) >= 500
            ? ApiException('Our photo checker is unavailable right now. Your photo was not lost; please try again later.')
            : err,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final steps = m.steps;
    return Scaffold(
      appBar: AppBar(title: Text(m.title, overflow: TextOverflow.ellipsis)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _photo != null
              ? Image.file(_photo!, height: 220, fit: BoxFit.cover)
              : m.imageUrl != null
                  ? NetImage(m.imageUrl, height: 200, radius: 0, icon: missionIcon(m))
                  : Container(
                      height: 180,
                      color: AppColors.mint,
                      alignment: Alignment.center,
                      child: Icon(missionIcon(m), size: 72, color: AppColors.primary),
                    ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: InfoTile(icon: Icons.toll_rounded, label: 'Points', value: '+${m.points}')),
          const SizedBox(width: 8),
          Expanded(child: InfoTile(icon: Icons.bolt_rounded, label: 'Pet XP', value: '+${m.xp}')),
          if (m.estimatedMinutes != null) ...[
            const SizedBox(width: 8),
            Expanded(child: InfoTile(icon: Icons.schedule_rounded, label: 'Time', value: '${m.estimatedMinutes} min')),
          ] else if (m.difficulty != null) ...[
            const SizedBox(width: 8),
            Expanded(child: InfoTile(icon: Icons.speed_rounded, label: 'Level', value: m.difficulty!)),
          ],
        ]),
        const SizedBox(height: 20),
        Text('About this mission', style: t.titleLarge),
        const SizedBox(height: 6),
        Text(m.description, style: t.bodyMedium?.copyWith(height: 1.45)),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('How to complete it', style: t.titleLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(steps[i], style: t.bodyMedium)),
              ]),
            ),
        ],
        if (_photo != null) ...[
          const SizedBox(height: 16),
          TextButton.icon(onPressed: _chooseSource, icon: const Icon(Icons.refresh_rounded), label: const Text('Retake photo')),
        ],
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: m.completedToday
              ? const FilledButton(onPressed: null, child: Text('Done for today – come back tomorrow'))
              : _photo == null
              ? FilledButton.icon(
                  onPressed: _chooseSource,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: const Text('Start mission – add photo proof'),
                )
              : LoadingButton(label: 'Submit proof', icon: Icons.send_rounded, loading: _loading, onPressed: _submit),
        ),
      ),
    );
  }
}
