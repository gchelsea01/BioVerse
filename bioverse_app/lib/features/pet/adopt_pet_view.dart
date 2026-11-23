import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../core/widgets/pet_art.dart';
import '../../models/conservation.dart';
import '../../models/gamification.dart';
import '../../state/services.dart';
import '../../state/session.dart';

/// Shown on the Pet tab when the user has no pet yet. Species come from
/// `/pets/species`, grouped by the ecosystem they belong to.
class AdoptPetView extends StatelessWidget {
  const AdoptPetView({super.key});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<PetSpecies>>(
      load: () => context.read<Services>().game.species(),
      isEmpty: (l) => l.isEmpty,
      empty: const EmptyState(title: 'No companions available yet', icon: Icons.pets_outlined),
      builder: (context, species, _) => _AdoptForm(species: species),
    );
  }
}

class _AdoptForm extends StatefulWidget {
  const _AdoptForm({required this.species});
  final List<PetSpecies> species;

  @override
  State<_AdoptForm> createState() => _AdoptFormState();
}

class _AdoptFormState extends State<_AdoptForm> {
  late PetSpecies _choice = widget.species.first;
  Ecosystem? _filter;
  final _name = TextEditingController(text: 'Buddy');
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _adopt() async {
    if (_name.text.trim().isEmpty) {
      showMessage(context, 'Give your buddy a name first.');
      return;
    }
    setState(() => _loading = true);
    try {
      final pet = await context.read<Services>().game.createPet(
            name: _name.text,
            species: _choice.id,
            displayName: _choice.name,
          );
      if (mounted) context.read<Session>().setPet(pet);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final shown = widget.species.where((s) => _filter == null || s.ecosystem == _filter).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      Text('Adopt your eco buddy', style: t.headlineSmall),
      const SizedBox(height: 6),
      Text(
        'Your buddy grows when you help the planet: care for it daily, complete eco missions, and donate.',
        style: t.bodyMedium?.copyWith(color: AppColors.textMuted),
      ),
      const SizedBox(height: 16),
      HabitatBackground(
        ecosystem: _choice.ecosystem,
        child: SizedBox(
          height: 200,
          child: Center(child: PetArt(species: _choice.id, stage: GrowthStage.juvenile, size: 170)),
        ),
      ),
      const SizedBox(height: 16),
      Text('Choose a companion', style: t.titleMedium),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final e in <Ecosystem?>[null, ...Ecosystem.values])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: _filter == e,
                onSelected: (_) => setState(() => _filter = e),
                label: Text(e == null ? 'All' : e == Ecosystem.coral ? 'Ocean' : e.label),
                labelStyle: TextStyle(color: _filter == e ? Colors.white : AppColors.navy, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      for (final s in shown)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: s == _choice ? AppColors.mint : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: s == _choice ? AppColors.primary : AppColors.border, width: s == _choice ? 2 : 1),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onTap: () => setState(() => _choice = s),
              leading: SizedBox(
                width: 48,
                height: 48,
                child: s.imageUrl != null
                    ? NetImage(s.imageUrl, width: 48, height: 48, icon: s.ecosystem.icon)
                    : PetArt(species: s.id, stage: GrowthStage.hatchling, size: 48),
              ),
              title: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                EcosystemTag(s.ecosystem),
                StatusChip(Fmt.enumLabel(s.rarity), tone: s.rarity == 'common' ? Tone.neutral : Tone.info),
              ]),
              subtitle: Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      const SizedBox(height: 8),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name your buddy')),
      const SizedBox(height: 16),
      LoadingButton(label: 'Adopt ${_choice.name}', loading: _loading, onPressed: _adopt, icon: Icons.pets_rounded),
    ]);
  }
}
