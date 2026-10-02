import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_theme.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_ui.dart';
import '../../../players/presentation/widgets/people_widgets.dart';
import '../../data/plans_api.dart';

/// Member-facing subscription page — port of `manage/equipes/abonnement.php`:
/// the active plans (`GET /plans`) and, after "Souscrire", the payment step
/// (Sank / Orange / Moov Money). Display only: no real payment is made.
class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  PlanInfo? _selected;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);

    return PopScope(
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selected != null) setState(() => _selected = null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selected == null ? 'Abonnements' : 'Paiement'),
          leading: _selected == null ? null : BackButton(onPressed: () => setState(() => _selected = null)),
        ),
        body: PageBody(
          maxWidth: 1000,
          onRefresh: () async => ref.invalidate(plansProvider),
          children: [
            if (_selected != null)
              _PaymentView(plan: _selected!)
            else ...[
              const HeroHeader(
                title: "Nos plans d'abonnement",
                subtitle: 'Choisissez la formule adaptée à votre club',
                leading: Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),
              plansAsync.when(
                loading: () => Column(children: [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonBox(height: 200, radius: 24))]),
                error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(plansProvider)),
                data: (plans) {
                  if (plans.isEmpty) return const EmptyState(icon: Icons.workspace_premium_outlined, title: 'Aucun plan disponible');
                  return LayoutBuilder(builder: (context, c) {
                    final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 600 ? 2 : 1);
                    final w = (c.maxWidth - (cols - 1) * 16) / cols;
                    final highlight = plans.length > 2 ? plans[plans.length ~/ 2].id : -1;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [for (final p in plans) SizedBox(width: w, child: _PlanCard(plan: p, highlighted: p.id == highlight, onSelect: () => setState(() => _selected = p)))],
                    );
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanInfo plan;
  final bool highlighted;
  final VoidCallback onSelect;
  const _PlanCard({required this.plan, required this.highlighted, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final free = plan.prix == 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: highlighted ? AppColors.primary : AppColors.border, width: highlighted ? 2 : 1),
        boxShadow: highlighted ? [BoxShadow(color: AppColors.primary.withAlpha(40), blurRadius: 24, offset: const Offset(0, 10))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.image != null) AppCover(imageUrl: plan.image, height: 120, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(plan.nom, style: t.titleLarge)),
                  if (highlighted) const StatusBadge(label: 'Populaire', solid: true, icon: Icons.star),
                ]),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(free ? 'Gratuit' : plan.priceLabel, style: t.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                  if (!free) Padding(padding: const EdgeInsets.only(left: 6, bottom: 4), child: Text('/ mois', style: t.bodySmall)),
                ]),
                const SizedBox(height: 12),
                Text(plan.description ?? '', style: t.bodyMedium, maxLines: 6, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                highlighted
                    ? FilledButton(onPressed: onSelect, child: const Text('Souscrire'))
                    : OutlinedButton(onPressed: onSelect, child: const Text('Souscrire')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Procéder au paiement": three provider tabs, exactly like the legacy page.
class _PaymentView extends StatefulWidget {
  final PlanInfo plan;
  const _PaymentView({required this.plan});

  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final _phone = TextEditingController();
  final _otp = TextEditingController();

  @override
  void dispose() {
    _tabs.dispose();
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  void _info(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SurfaceCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Procéder au paiement', style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabs,
                tabs: const [Tab(text: 'Sank Money'), Tab(text: 'Orange Money'), Tab(text: 'Moov Money')],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.info.withAlpha(24), borderRadius: BorderRadius.circular(14)),
                child: Text.rich(TextSpan(style: t.bodyMedium, children: [
                  const TextSpan(text: "Vous avez choisi le plan de l'abonnement "),
                  TextSpan(text: widget.plan.nom, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const TextSpan(text: ' pour un prix de '),
                  TextSpan(text: widget.plan.priceLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const TextSpan(text: ". Veuillez procéder aux étapes suivantes pour effectuer le paiement et ainsi valider cet abonnement."),
                ])),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _tabs,
                builder: (context, _) => switch (_tabs.index) {
                  0 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Pour obtenir un code OTP, saisissez votre numéro de téléphone ayant un compte Sank Money puis appuyez sur « Générer OTP ».', style: t.bodySmall),
                      const SizedBox(height: 12),
                      TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro Sank Money', hintText: 'Votre numéro de téléphone Sank Money')),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: TextField(controller: _otp, decoration: const InputDecoration(labelText: 'Code OTP', hintText: 'Le code OTP reçu par SMS'))),
                        const SizedBox(width: 10),
                        OutlinedButton(onPressed: () => _info("Le paiement en ligne n'est pas encore activé sur cette version."), child: const Text('Générer OTP')),
                      ]),
                      const SizedBox(height: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.secondary),
                        onPressed: () => _info("Le paiement en ligne n'est pas encore activé sur cette version."),
                        child: const Text('Payer avec Sank Money'),
                      ),
                    ]),
                  1 => Column(children: [
                      const SizedBox(height: 12),
                      Text('Pour obtenir un code OTP, tapez *144*4*6*${widget.plan.prix.round()}# puis choisissez « Paiement marchand ».', style: t.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      const StatusBadge(label: 'Sera bientôt disponible', color: AppColors.warning, icon: Icons.schedule),
                    ]),
                  _ => Column(children: [
                      const SizedBox(height: 12),
                      Text('Pour générer un code OTP, composez *155# puis suivez les instructions pour le paiement par mobile.', style: t.bodySmall, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      const StatusBadge(label: 'Sera bientôt disponible', color: AppColors.warning, icon: Icons.schedule),
                    ]),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
