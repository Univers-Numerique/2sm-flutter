import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../auth/application/auth_provider.dart';
import '../../application/fields_providers.dart';
import '../../data/fields_repository.dart';
import '../../data/models/field.dart';

/// Ajouter / modifier un stade (compte/ajouter-stade.php) : photo, nom, lieu,
/// localisation (latitude / longitude), manager, conditions.
class CreateFieldScreen extends ConsumerStatefulWidget {
  final Field? field;
  const CreateFieldScreen({super.key, this.field});

  @override
  ConsumerState<CreateFieldScreen> createState() => _CreateFieldScreenState();
}

class _CreateFieldScreenState extends ConsumerState<CreateFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomController = TextEditingController(text: widget.field?.nomTerrain);
  late final _lieuController = TextEditingController(text: widget.field?.lieu);
  late final _latController = TextEditingController(text: widget.field?.latitude?.toString());
  late final _lngController = TextEditingController(text: widget.field?.longitude?.toString());
  File? _photo;
  bool _accept = false;
  bool _loading = false;
  String? _error;

  bool get _isEditing => widget.field != null;

  @override
  void initState() {
    super.initState();
    _accept = _isEditing;
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accept) {
      setState(() => _error = 'Veuillez accepter les conditions.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(fieldsRepositoryProvider);
      String? orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      final lat = double.tryParse(_latController.text.trim().replaceAll(',', '.'));
      final lng = double.tryParse(_lngController.text.trim().replaceAll(',', '.'));
      Field saved;
      if (_isEditing) {
        saved = await repo.update(widget.field!.id, nomTerrain: _nomController.text.trim(), lieu: orNull(_lieuController), latitude: lat, longitude: lng);
        ref.invalidate(fieldDetailProvider(widget.field!.id));
      } else {
        saved = await repo.create(nomTerrain: _nomController.text.trim(), lieu: orNull(_lieuController), latitude: lat, longitude: lng);
      }
      if (_photo != null && saved.id > 0) await repo.uploadPhoto(saved.id, _photo!);
      ref.invalidate(fieldsListProvider);
      if (mounted) context.pop();
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Une erreur est survenue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _lieuController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  String? _validateCoordinate(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return double.tryParse(v.trim().replaceAll(',', '.')) == null ? 'Nombre invalide' : null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final manager = auth is AuthAuthenticated ? auth.user.fullName : '';
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Modifier le stade' : 'Ajouter un stade')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HeroHeader(
                      title: _isEditing ? 'Modifier le stade' : 'Ajouter un stade',
                      subtitle: 'Remplissez les informations du stade.',
                      leading: const Icon(Icons.stadium_outlined, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 16),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onTap: _pickPhoto,
                            child: Stack(children: [
                              _photo != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_photo!, height: 170, width: double.infinity, fit: BoxFit.cover))
                                  : AppCover(imageUrl: widget.field?.photo, height: 170),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                  child: const Row(children: [
                                    Icon(Icons.photo_camera_outlined, color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text('Téléchargez une photo', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ]),
                                ),
                              ),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(labelText: 'Nom du terrain/stade'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _lieuController,
                            decoration: const InputDecoration(labelText: 'Lieu du terrain/stade'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                decoration: const InputDecoration(labelText: 'Latitude'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                validator: _validateCoordinate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                decoration: const InputDecoration(labelText: 'Longitude'),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                validator: _validateCoordinate,
                              ),
                            ),
                          ]),
                          const SizedBox(height: 12),
                          InputDecorator(
                            decoration: const InputDecoration(labelText: 'Manager'),
                            child: Row(children: [
                              AppAvatar(name: manager.isEmpty ? '?' : manager, size: 24),
                              const SizedBox(width: 8),
                              Text(manager),
                            ]),
                          ),
                          CheckboxListTile(
                            value: _accept,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (v) => setState(() => _accept = v ?? false),
                            title: const Text("J'accepte les conditions d'utilisation"),
                          ),
                          if (_error != null)
                            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: AppColors.error))),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: Text(_loading ? 'Enregistrement…' : (_isEditing ? 'ENREGISTRER' : 'ENREGISTRER LE STADE')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
