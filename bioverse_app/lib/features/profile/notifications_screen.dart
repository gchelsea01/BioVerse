import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/common.dart';
import '../../models/user.dart';
import '../../state/services.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _version = 0;
  final _read = <String>{};

  Future<void> _readAll() async {
    try {
      await context.read<Services>().user.markAllRead();
      if (mounted) setState(() => _version++);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  IconData _icon(String type) {
    if (type.contains('donation') || type.contains('payment')) return Icons.volunteer_activism_rounded;
    if (type.contains('mission')) return Icons.flag_rounded;
    if (type.contains('milestone') || type.contains('coral') || type.contains('photo')) return Icons.photo_camera_rounded;
    if (type.contains('streak')) return Icons.local_fire_department_rounded;
    return Icons.notifications_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: _readAll, child: const Text('Mark all read'))],
      ),
      body: AsyncView<List<AppNotification>>(
        key: ValueKey(_version),
        load: () => context.read<Services>().user.notifications(),
        isEmpty: (l) => l.isEmpty,
        empty: const EmptyState(title: "You're all caught up", icon: Icons.notifications_none_rounded),
        builder: (context, items, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(indent: 72),
            itemBuilder: (_, i) {
              final n = items[i];
              final unread = !n.isRead && !_read.contains(n.id);
              return ListTile(
                tileColor: unread ? AppColors.mint : null,
                leading: CircleAvatar(backgroundColor: AppColors.mintStrong, child: Icon(_icon(n.type), color: AppColors.primary)),
                title: Text(n.title, style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.body),
                  const SizedBox(height: 2),
                  Text(Fmt.relative(n.createdAt), style: t.labelSmall?.copyWith(color: AppColors.textMuted)),
                ]),
                onTap: unread
                    ? () {
                        setState(() => _read.add(n.id));
                        context.read<Services>().user.markRead(n.id).catchError((_) {});
                      }
                    : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
