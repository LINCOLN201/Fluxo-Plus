import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/premium/premium_entitlement.dart';
import '../../../core/premium/premium_service.dart';
import '../../../core/theme/app_colors.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, required this.service});

  final PremiumService service;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late Future<PremiumEntitlement> _entitlement;

  @override
  void initState() {
    super.initState();
    _entitlement = widget.service.load();
  }

  void _refresh() {
    setState(() => _entitlement = widget.service.load(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluxo+ Premium'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Atualizar assinatura',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<PremiumEntitlement>(
        future: _entitlement,
        builder: (context, snapshot) {
          final entitlement = snapshot.data ?? const PremiumEntitlement.free();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _Hero(entitlement: entitlement),
              const SizedBox(height: 22),
              Text(
                'Escolha seu plano',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    const _PlanCard(
                      title: 'Mensal',
                      price: 'R\$ 9,90',
                      detail: 'por mês',
                    ),
                    const _PlanCard(
                      title: 'Anual',
                      price: 'R\$ 79,90',
                      detail: 'economize 32%',
                      featured: true,
                    ),
                  ];
                  if (constraints.maxWidth < 760) {
                    return Column(
                      children: [
                        for (final card in cards) ...[
                          card,
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var index = 0; index < cards.length; index++) ...[
                        Expanded(child: cards[index]),
                        if (index != cards.length - 1)
                          const SizedBox(width: 12),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _Benefits(),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'As assinaturas ainda não estão abertas. '
                      'Nenhuma cobrança foi realizada.',
                    ),
                  ),
                ),
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text('Quero conhecer o Premium'),
              ),
              const SizedBox(height: 10),
              Text(
                'O aplicativo local continuará gratuito e open source. '
                'A cobrança será ativada somente após integração oficial.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.entitlement});

  final PremiumEntitlement entitlement;

  String get _detail {
    if (entitlement.isActive) {
      final end = entitlement.status == 'trialing'
          ? entitlement.trialEndsAt
          : entitlement.currentPeriodEnd;
      return end == null
          ? 'Todos os recursos Premium estão ativos.'
          : 'Ativo até ${DateFormat('dd/MM/yyyy', 'pt_BR').format(end)}.';
    }
    return 'Transações, contas, relatórios, metas e backup local '
        'ilimitados, sem custo.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = entitlement.isActive;
    final accent = active ? colors.primary : colors.textMuted;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: active ? colors.primary : colors.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SEU PLANO ATUAL',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              _StatusPill(active: active),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  active
                      ? Icons.workspace_premium_rounded
                      : Icons.verified_user_outlined,
                  color: accent,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entitlement.label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_detail, style: TextStyle(color: colors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (!active && !AppConstants.premiumEnforced) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration_outlined,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Durante o lançamento, os recursos Premium estão '
                      'liberados para todos.',
                      style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: active ? colors.primary : colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_rounded : Icons.circle,
            size: active ? 14 : 8,
            color: active ? colors.onPrimary : colors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            active ? 'Ativo' : 'Em uso',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: active ? colors.onPrimary : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.detail,
    this.featured = false,
  });

  final String title;
  final String price;
  final String detail;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: featured
            ? BorderSide(color: context.colors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (featured)
                  const Chip(
                    label: Text('Melhor valor'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              price,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(detail, style: TextStyle(color: context.colors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    const groups = [
      (
        Icons.cloud_done_outlined,
        'Nuvem',
        'Backup na nuvem, sincronização entre aparelhos e histórico.'
      ),
      (
        Icons.palette_outlined,
        'Personalização',
        'Paleta de cores exclusiva para as suas categorias.'
      ),
      (
        Icons.event_repeat_rounded,
        'Organização',
        'Recorrências, cartões, parcelas e orçamentos.'
      ),
      (
        Icons.insights_rounded,
        'Relatórios',
        'Tendências, patrimônio, PDF e Excel.'
      ),
      (
        Icons.auto_awesome_rounded,
        'Inteligência',
        'Análises, alertas e previsões no roadmap.'
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            for (var index = 0; index < groups.length; index++) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      context.colors.primary.withValues(alpha: .14),
                  child: Icon(groups[index].$1, color: context.colors.primary),
                ),
                title: Text(
                  groups[index].$2,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(groups[index].$3),
              ),
              if (index != groups.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}
