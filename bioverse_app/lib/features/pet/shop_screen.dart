import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/gamification.dart';
import '../../state/services.dart';
import '../../state/session.dart';

IconData _itemIcon(String type) => switch (type) {
      'streak_freeze' => Icons.ac_unit_rounded,
      'pet_skin' => Icons.palette_rounded,
      'pet_accessory' => Icons.checkroom_rounded,
      'habitat_background' => Icons.landscape_rounded,
      'xp_boost_item' => Icons.bolt_rounded,
      _ => Icons.card_giftcard_rounded,
    };

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final points = context.watch<Session>().points;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pet shop'),
          actions: [PointsPill(points: points), const SizedBox(width: 12)],
          bottom: const TabBar(
            labelColor: AppColors.navy,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            tabs: [Tab(text: 'Shop'), Tab(text: 'My items')],
          ),
        ),
        body: const TabBarView(children: [_ShopTab(), _InventoryTab()]),
      ),
    );
  }
}

class _ShopTab extends StatelessWidget {
  const _ShopTab();

  Future<void> _buy(BuildContext context, ShopProduct p) async {
    final session = context.read<Session>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Buy ${p.name}?'),
        content: Text('This uses ${Fmt.number(p.pricePoints)} of your ${Fmt.number(session.points)} points.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not now')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final remaining = await context.read<Services>().game.buy(p.id);
      session.setPoints(remaining);
      if (context.mounted) showMessage(context, '${p.name} added to My items.');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final points = context.watch<Session>().points;
    return AsyncView<List<ShopProduct>>(
      load: () => context.read<Services>().game.products(),
      isEmpty: (l) => l.isEmpty,
      empty: const EmptyState(title: 'The shop is empty for now', icon: Icons.storefront_outlined),
      builder: (context, items, _) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = items[i];
          final affordable = points >= p.pricePoints;
          return Panel(
            child: Row(children: [
              SizedBox(
                width: 56,
                height: 56,
                child: p.previewUrl != null
                    ? NetImage(p.previewUrl, icon: _itemIcon(p.itemType))
                    : Container(
                        decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                        child: Icon(_itemIcon(p.itemType), color: AppColors.primary),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(p.description, style: t.bodySmall?.copyWith(color: AppColors.textMuted), maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 12)),
                onPressed: affordable ? () => _buy(context, p) : null,
                icon: const Icon(Icons.toll_rounded, size: 16),
                label: Text(Fmt.compact(p.pricePoints)),
              ),
            ]),
          );
        },
      ),
    );
  }
}

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  Future<void> _equip(BuildContext context, InventoryItem item) async {
    final session = context.read<Session>();
    final pet = session.pet;
    if (pet == null) {
      showMessage(context, 'Adopt a pet first.');
      return;
    }
    try {
      final updated = await context.read<Services>().game.equip(pet.id, item.productId);
      session.setPet(updated);
      if (context.mounted) showMessage(context, '${item.name} equipped on ${pet.name}.');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final equipped = context.watch<Session>().pet?.equippedProductId;
    return AsyncView<List<InventoryItem>>(
      load: () => context.read<Services>().game.inventory(),
      isEmpty: (l) => l.isEmpty,
      empty: const EmptyState(title: 'No items yet', message: 'Buy items in the Shop tab with your points.', icon: Icons.backpack_outlined),
      builder: (context, items, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final item = items[i];
            final isOn = item.productId == equipped;
            return Panel(
              child: Row(children: [
                CircleAvatar(backgroundColor: AppColors.mint, child: Icon(_itemIcon(item.itemType), color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.name, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text('${Fmt.enumLabel(item.itemType)} • x${item.quantity}', style: t.bodySmall?.copyWith(color: AppColors.textMuted)),
                  ]),
                ),
                if (isOn)
                  const StatusChip('Equipped', tone: Tone.success)
                else if (item.isEquippable)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => _equip(context, item),
                    child: const Text('Equip'),
                  ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
