import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../core/network/failure.dart';
import '../../application/news_providers.dart';
import '../../data/models/news.dart';
import '../../data/news_repository.dart';
import '../news_html_style.dart';

/// Legacy `publier.php`: "Rédigez votre publication" with a light HTML
/// editor (bold / italic / heading / list / link toolbar and live preview),
/// Publier / Annuler. `contenu` is stored as HTML like on the old site.
/// Pass [editing] to update an existing article (author only).
class ComposeNewsScreen extends ConsumerStatefulWidget {
  final News? editing;
  const ComposeNewsScreen({super.key, this.editing});

  @override
  ConsumerState<ComposeNewsScreen> createState() => _ComposeNewsScreenState();
}

class _ComposeNewsScreenState extends ConsumerState<ComposeNewsScreen> {
  late final TextEditingController _controller = TextEditingController(text: widget.editing?.contenu ?? '');
  bool _loading = false;
  bool _preview = false;
  String? _error;

  bool get _isEditing => widget.editing != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _wrap(String open, String close, {String placeholder = 'texte'}) {
    final sel = _controller.selection;
    final text = _controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final chosen = start == end ? placeholder : text.substring(start, end);
    final next = text.replaceRange(start, end, '$open$chosen$close');
    _controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + open.length + chosen.length + close.length),
    );
  }

  Future<void> _link() async {
    final ctrl = TextEditingController(text: 'https://');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insérer un lien'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Adresse du lien')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Insérer')),
        ],
      ),
    );
    if (url != null && url.isNotEmpty) _wrap('<a href="$url">', '</a>', placeholder: 'lien');
  }

  String _toHtml(String raw) {
    final t = raw.trim();
    // Already markup: keep as-is. Plain text: wrap paragraphs.
    if (RegExp(r'<[a-zA-Z][^>]*>').hasMatch(t)) return t;
    return t.split(RegExp(r'\n{2,}')).map((p) => '<p>${p.replaceAll('\n', '<br>')}</p>').join();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Rédigez votre publication avant de publier.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final contenu = _toHtml(text);
    try {
      final repo = ref.read(newsRepositoryProvider);
      if (_isEditing) {
        await repo.update(widget.editing!.id, contenu);
        ref.invalidate(newsDetailProvider(widget.editing!.id));
      } else {
        await repo.create(contenu);
      }
      if (mounted) context.pop();
    } on Failure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Modifier l'actualité" : 'Rédigez votre publication'),
        actions: [
          IconButton(
            tooltip: _preview ? 'Éditer' : 'Aperçu',
            onPressed: () => setState(() => _preview = !_preview),
            icon: Icon(_preview ? Icons.edit_note : Icons.visibility_outlined),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              if (!_preview)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _tool(Icons.format_bold, 'Gras', () => _wrap('<strong>', '</strong>')),
                    _tool(Icons.format_italic, 'Italique', () => _wrap('<em>', '</em>')),
                    _tool(Icons.title, 'Titre', () => _wrap('<h2>', '</h2>', placeholder: 'Titre')),
                    _tool(Icons.format_list_bulleted, 'Liste', () => _wrap('<ul><li>', '</li></ul>', placeholder: 'élément')),
                    _tool(Icons.format_quote, 'Paragraphe', () => _wrap('<p>', '</p>')),
                    _tool(Icons.link, 'Lien', _link),
                    _tool(Icons.image_outlined, 'Image (URL)', () async {
                      final ctrl = TextEditingController(text: 'https://');
                      final url = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Insérer une image"),
                          content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: "Adresse de l'image")),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Insérer')),
                          ],
                        ),
                      );
                      if (url != null && url.isNotEmpty) _wrap('<img src="$url" alt="">', '', placeholder: '');
                    }),
                  ]),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: _preview
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: SingleChildScrollView(child: Html(data: _toHtml(_controller.text), style: newsHtmlStyle)),
                      )
                    : TextField(
                        controller: _controller,
                        expands: true,
                        maxLines: null,
                        minLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(hintText: 'Rédigez votre publication…', alignLabelWithHint: true),
                      ),
              ),
              if (_error != null)
                Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : () => context.pop(),
                    icon: const Icon(Icons.close),
                    label: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isEditing ? 'Enregistrer' : 'Publier'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tool(IconData icon, String tip, VoidCallback onTap) => IconButton(tooltip: tip, onPressed: onTap, icon: Icon(icon));
}
