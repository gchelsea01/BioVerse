import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/pet_art.dart';
import '../../models/conservation.dart';
import '../../models/gamification.dart';
import '../../state/services.dart';
import '../../state/session.dart';

class _Species {
  const _Species(this.ecosystem, this.type, this.blurb);
  final Ecosystem ecosystem;
  final String type;
  final String blurb;
}

/// Pet species offered at adoption. The backend accepts free text here; move
/// to an API list once it exists (docs/BACKEND_NOTES.md #8).
const _species = [
  _Species(Ecosystem.coral, 'Acropora', 'A branching reef builder that shelters fish.'),
  _Species(Ecosystem.mangrove, 'Rhizophora', 'Coastal guardian whose roots stop erosion.'),
  _Species(Ecosystem.tree, 'Mahogany', 'A forest tree that keeps hillsides green.'),
];

/// Shown on the Pet tab when the user has no pet yet.
class AdoptPetView extends StatefulWidget {
  const AdoptPetView({super.key});

  @override
  State<AdoptPetView> createState() => _AdoptPetViewState();
}

class _AdoptPetViewState extends State<AdoptPetView> {
  _Species _choice = _species.first;
  final _name = TextEditingController(text: 'Reefy');
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
            species: _choice.ecosystem.api,
            coralType: _choice.type,
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
          child: Center(child: PetArt(species: _choice.ecosystem.api, stage: GrowthStage.juvenile, size: 170)),
        ),
      ),
      const SizedBox(height: 16),
      Text('Choose a species', style: t.titleMedium),
      const SizedBox(height: 8),
      for (final s in _species)
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
              leading: PetArt(species: s.ecosystem.api, stage: GrowthStage.hatchling, size: 44),
              title: Row(children: [
                Text(s.type, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                EcosystemTag(s.ecosystem),
              ]),
              subtitle: Text(s.blurb),
            ),
          ),
        ),
      const SizedBox(height: 8),
      TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name your buddy')),
      const SizedBox(height: 16),
      LoadingButton(label: 'Adopt ${_choice.type}', loading: _loading, onPressed: _adopt, icon: Icons.pets_rounded),
    ]);
  }
}
