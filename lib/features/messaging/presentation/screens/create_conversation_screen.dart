import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/failure.dart';
import '../../application/messaging_providers.dart';
import '../../data/conversations_repository.dart';
import '../../data/models/conversation.dart';

/// Legacy `creer-conversation.php`: "Créer ou mettre à jour votre groupe de
/// discussion" - visibility (Privé / Public), subject, description and the
/// conditions checkbox. Pass [existing] to update a group.
class CreateConversationScreen extends ConsumerStatefulWidget {
  final Conversation? existing;
  const CreateConversationScreen({super.key, this.existing});

  @override
  ConsumerState<CreateConversationScreen> createState() => _CreateConversationScreenState();
}

class _CreateConversationScreenState extends ConsumerState<CreateConversationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _sujet = TextEditingController(text: widget.existing?.sujet ?? '');
  late final _description = TextEditingController(text: widget.existing?.description ?? '');
  late bool _public = widget.existing == null ? true : widget.existing!.isPublic;
  late bool _accepted = widget.existing != null;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _sujet.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepted) {
      setState(() => _error = "Acceptez les conditions de création de groupe de conversation.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(conversationsRepositoryProvider);
      final type = _public ? 'public' : 'prive';
      if (widget.existing == null) {
        await repo.create(sujet: _sujet.text.trim(), description: _description.text.trim(), type: type);
      } else {
        await repo.updateGroup(widget.existing!.id, sujet: _sujet.text.trim(), description: _description.text.trim(), type: type);
        ref.invalidate(conversationDetailProvider(widget.existing!.id));
      }
      ref.invalidate(myConversationsProvider);
      ref.invalidate(groupDirectoryProvider);
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
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Mettre à jour le groupe' : 'Créer un groupe')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Créer ou mettre à jour votre groupe de discussion', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text('Remplissez les informations de votre groupe de discussion.', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                Text('Visibilité du groupe', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.lock_outline), label: Text('Privé')),
                    ButtonSegment(value: true, icon: Icon(Icons.public), label: Text('Public')),
                  ],
                  selected: {_public},
                  onSelectionChanged: (s) => setState(() => _public = s.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sujet,
                  decoration: const InputDecoration(labelText: 'Sujet de la conversation', prefixIcon: Icon(Icons.forum_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'Description du groupe', alignLabelWithHint: true),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  title: const Text("J'ai lu et j'accepte les conditions de création de groupe de conversation"),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(editing ? 'ENREGISTRER' : 'CRÉER LE GROUPE'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
