import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../application/admin_providers.dart';
import '../../data/admin_config.dart';
import '../../data/admin_repository.dart';
import '../widgets/admin_widgets.dart';

/// Legacy `admin/gerer.php?table=…&id=…`: one generic editor for
/// utilisateurs / équipes / compétitions / terrains — picture, name, current
/// status (icon + badge) and a select of that table's statuses with
/// "Mettre à jour".
class AdminManageScreen extends ConsumerStatefulWidget {
  final AdminEntity entity;
  final int id;
  const AdminManageScreen({super.key, required this.entity, required this.id});

  @override
  ConsumerState<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends ConsumerState<AdminManageScreen> {
  int? _selected;
  bool _saving = false;

  AdminSection get _section {
    switch (widget.entity) {
      case AdminEntity.utilisateurs:
        return AdminSection.users;
      case AdminEntity.equipes:
        return AdminSection.teams;
      case AdminEntity.competitions:
        return AdminSection.competitions;
      case AdminEntity.terrains:
        return AdminSection.fields;
    }
  }

  void _refreshLists() {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminTeamsProvider);
    ref.invalidate(adminCompetitionsProvider);
    ref.invalidate(adminFieldsProvider);
    ref.invalidate(adminTargetProvider((entity: widget.entity, id: widget.id)));
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _saving = true);
    try {
      await action();
      _refreshLists();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
    } on Failure catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = (entity: widget.entity, id: widget.id);
    final async = ref.watch(adminTargetProvider(args));

    return AdminScaffold(
      title: 'Gérer · ${widget.entity.label}',
      section: _section,
      body: async.when(
        loading: () => const Padding(padding: EdgeInsets.all(24), child: SkeletonBox(height: 420, radius: 24)),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(adminTargetProvider(args))),
        data: (target) => _buildContent(context, target),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdminManageTarget target) {
    final text = Theme.of(context).textTheme;
    final options = AdminStatus.forEntity(widget.entity);
    final current = AdminStatus.optionFor(widget.entity, target.statut);

    // Options the editor offers; for users, legacy statuses that would grant
    // administration (4..7) are display-only.
    final selectable = widget.entity == AdminEntity.utilisateurs
        ? options.where((o) => AdminStatus.editableUsers.contains(o.value)).toList()
        : options;
    final selectedValue = _selected ?? (selectable.any((o) => o.value == target.statut) ? target.statut : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Column(
                  children: [
                    AppAvatar(
                      name: target.name,
                      imageUrl: target.image,
                      size: 120,
                      rounded: widget.entity != AdminEntity.utilisateurs,
                      border: Border.all(color: AppColors.border, width: 3),
                    ),
                    const SizedBox(height: 16),
                    Text(target.name, style: text.headlineSmall, textAlign: TextAlign.center),
                    if (target.subtitle != null && target.subtitle!.isNotEmpty)
                      Text(target.subtitle!, style: text.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: current.color.withAlpha(24), borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        children: [
                          Icon(current.icon, size: 48, color: current.color),
                          const SizedBox(height: 6),
                          Text(
                            current.label,
                            style: text.titleLarge?.copyWith(color: current.color),
                          ),
                          if (widget.entity == AdminEntity.utilisateurs && target.isBlocked)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: StatusBadge(label: 'Compte bloqué', color: AppColors.error, icon: Icons.block, solid: true),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    DropdownButtonFormField<int>(
                      value: selectedValue,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Statut', prefixIcon: Icon(Icons.flag_outlined)),
                      items: [
                        for (final o in selectable)
                          DropdownMenuItem<int>(
                            value: o.value,
                            child: Row(
                              children: [
                                Icon(o.icon, size: 18, color: o.color),
                                const SizedBox(width: 10),
                                Text(o.label),
                              ],
                            ),
                          ),
                      ],
                      onChanged: _saving ? null : (v) => setState(() => _selected = v),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving || selectedValue == null || selectedValue == target.statut
                            ? null
                            : () => _run(
                                  () => ref.read(adminRepositoryProvider).updateStatus(widget.entity, target.id, selectedValue),
                                  'Statut mis à jour.',
                                ),
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check),
                        label: const Text('Mettre à jour'),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.entity == AdminEntity.utilisateurs) ...[
                const SizedBox(height: 16),
                _UserPrivileges(
                  target: target,
                  busy: _saving,
                  onBlock: (v) => _run(
                    () => ref.read(adminRepositoryProvider).setUserBlocked(target.id, v),
                    v ? 'Compte bloqué.' : 'Compte débloqué.',
                  ),
                  onAdmin: (v) => _run(
                    () => v
                        ? ref.read(adminRepositoryProvider).grantAdmin(target.id)
                        : ref.read(adminRepositoryProvider).revokeAdmin(target.id),
                    v ? 'Rôle administrateur accordé.' : 'Rôle administrateur révoqué.',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UserPrivileges extends StatelessWidget {
  final AdminManageTarget target;
  final bool busy;
  final ValueChanged<bool> onBlock;
  final ValueChanged<bool> onAdmin;
  const _UserPrivileges({required this.target, required this.busy, required this.onBlock, required this.onAdmin});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          SwitchListTile(
            value: target.isBlocked,
            onChanged: busy ? null : onBlock,
            secondary: const Icon(Icons.block, color: AppColors.error),
            title: const Text('Compte bloqué'),
            subtitle: const Text("L'utilisateur ne peut plus se connecter."),
          ),
          const Divider(height: 1),
          SwitchListTile(
            value: target.isAdmin,
            onChanged: busy ? null : onAdmin,
            secondary: const Icon(Icons.shield_outlined, color: AppColors.secondary),
            title: const Text('Administrateur du site'),
            subtitle: const Text("Accorde l'accès au back-office."),
          ),
        ],
      ),
    );
  }
}
