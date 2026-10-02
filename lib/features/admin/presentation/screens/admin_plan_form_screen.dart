import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../application/admin_providers.dart';
import '../../data/models/plan.dart';
import '../../data/plans_repository.dart';
import '../widgets/admin_widgets.dart';

/// Legacy `admin/plan.php`: create / edit a subscription plan — image with
/// preview + upload button, nom, prix, description and submit.
class AdminPlanFormScreen extends ConsumerStatefulWidget {
  final int? planId;
  final Plan? plan;
  const AdminPlanFormScreen({super.key, this.planId, this.plan});

  @override
  ConsumerState<AdminPlanFormScreen> createState() => _AdminPlanFormScreenState();
}

class _AdminPlanFormScreenState extends ConsumerState<AdminPlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prix = TextEditingController();
  final _description = TextEditingController();
  Plan? _plan;
  XFile? _image;
  bool _active = true;
  bool _saving = false;
  bool _initialised = false;

  bool get _isEdit => widget.planId != null || widget.plan != null;

  @override
  void dispose() {
    _nom.dispose();
    _prix.dispose();
    _description.dispose();
    super.dispose();
  }

  void _fill(Plan plan) {
    if (_initialised) return;
    _initialised = true;
    _plan = plan;
    _nom.text = plan.nom;
    _prix.text = plan.prix == plan.prix.roundToDouble() ? plan.prix.toStringAsFixed(0) : '${plan.prix}';
    _description.text = plan.description ?? '';
    _active = plan.statut == 1;
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file != null) setState(() => _image = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(plansRepositoryProvider);
    final prix = double.parse(_prix.text.trim().replaceAll(',', '.').replaceAll(' ', ''));
    try {
      if (_plan == null) {
        await repo.create(
          nom: _nom.text.trim(),
          prix: prix,
          description: _description.text.trim(),
          statut: _active ? 1 : 0,
          image: _image,
        );
      } else {
        await repo.update(
          _plan!.id,
          nom: _nom.text.trim(),
          prix: prix,
          description: _description.text.trim(),
          statut: _active ? 1 : 0,
          image: _image,
        );
      }
      ref.invalidate(plansListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_plan == null ? 'Plan créé.' : 'Plan mis à jour.')));
        context.pop();
      }
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plan != null) {
      _fill(widget.plan!);
    } else if (widget.planId != null && !_initialised) {
      final plans = ref.watch(plansListProvider).valueOrNull;
      final found = plans?.where((p) => p.id == widget.planId).firstOrNull;
      if (found != null) _fill(found);
    }
    final waiting = widget.planId != null && widget.plan == null && !_initialised;

    return AdminScaffold(
      title: _isEdit ? "Modifier le plan d'abonnement" : "Créer un plan d'abonnement",
      section: AdminSection.plans,
      body: waiting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(_isEdit ? 'Modifier le plan' : "Créer un plan d'abonnement",
                              style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text('Remplissez les informations.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          Center(child: _ImagePreview(picked: _image, current: _plan?.image, name: _nom.text)),
                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: _saving ? null : _pick,
                              icon: const Icon(Icons.image_outlined),
                              label: Text(_image == null ? "Téléchargez l'image du plan" : 'Changer l\'image'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nom,
                            decoration: const InputDecoration(labelText: 'Nom', prefixIcon: Icon(Icons.badge_outlined)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis.' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _prix,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Prix',
                              prefixIcon: Icon(Icons.payments_outlined),
                              suffixText: 'F CFA',
                            ),
                            validator: (v) {
                              final n = double.tryParse((v ?? '').trim().replaceAll(',', '.').replaceAll(' ', ''));
                              if (n == null || n < 0) return 'Entrez un prix valide.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _description,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _active,
                            onChanged: _saving ? null : (v) => setState(() => _active = v),
                            title: const Text('Plan actif'),
                            subtitle: const Text('Visible par les équipes.'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _saving ? null : _submit,
                            child: _saving
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(_isEdit ? 'ENREGISTRER LE PLAN' : 'CRÉER LE PLAN'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final XFile? picked;
  final String? current;
  final String name;
  const _ImagePreview({this.picked, this.current, required this.name});

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    if (picked != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(File(picked!.path), width: size, height: size, fit: BoxFit.cover),
      );
    }
    return AppAvatar(name: name.isEmpty ? 'Plan' : name, imageUrl: current, size: size, rounded: true);
  }
}
