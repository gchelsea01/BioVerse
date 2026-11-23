import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common.dart';
import '../../models/gamification.dart';
import '../../state/services.dart';
import '../../state/session.dart';

/// Proof photos are verified asynchronously; poll until a final status.
class SubmissionStatusScreen extends StatefulWidget {
  const SubmissionStatusScreen({super.key, required this.mission, required this.submission});
  final EcoMission mission;
  final MissionSubmission submission;

  @override
  State<SubmissionStatusScreen> createState() => _SubmissionStatusScreenState();
}

class _SubmissionStatusScreenState extends State<SubmissionStatusScreen> {
  late MissionSubmission _s = widget.submission;
  Timer? _timer;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    if (_s.isFinal) {
      // Verified on submit (the API can answer synchronously): refresh rewards now.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshRewards();
      });
    } else {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
    }
  }

  void _refreshRewards() {
    if (_s.status != 'verified') return;
    context.read<Session>()
      ..refreshUser()
      ..refreshGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (++_polls > 30) return _timer?.cancel();
    try {
      final s = await context.read<Services>().game.submission(_s.id);
      if (!mounted) return;
      setState(() => _s = s);
      if (s.isFinal) {
        _timer?.cancel();
        _refreshRewards();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (icon, color, title, body) = switch (_s.status) {
      'verified' => (
          Icons.verified_rounded,
          AppColors.success,
          'Mission complete!',
          'Your proof was verified. Points and XP have been added.',
        ),
      'rejected' => (
          Icons.cancel_rounded,
          AppColors.danger,
          'Proof not accepted',
          'We could not verify this photo. Make sure the item is clearly visible and try again.',
        ),
      'needs_review' => (
          Icons.manage_search_rounded,
          AppColors.warning,
          'Under manual review',
          'Our team will check your photo shortly. You will get a notification.',
        ),
      _ => (
          Icons.hourglass_top_rounded,
          AppColors.primary,
          'Checking your photo…',
          'This usually takes under a minute. You can leave this screen; we will notify you.',
        ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(widget.mission.title)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 24),
        Center(child: Icon(icon, size: 88, color: color)),
        if (!_s.isFinal) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: t.headlineSmall),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 24),
        Panel(
          child: Column(children: [
            KeyValue('Status', Fmt.enumLabel(_s.status)),
            KeyValue('Submitted', Fmt.dateTime(_s.createdAt)),
            KeyValue('Points', _s.awardedPoints != null ? '+${_s.awardedPoints}' : '+${widget.mission.points} (pending)'),
            KeyValue('Pet XP', _s.awardedXp != null ? '+${_s.awardedXp}' : '+${widget.mission.xp} (pending)'),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
        ),
      ),
    );
  }
}
