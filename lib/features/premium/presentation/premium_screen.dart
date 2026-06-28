import 'package:flutter/material.dart';

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
                    const _PlanCard(
                      title: 'Vitalício',
                      price: 'R\$ 149,90',
                      detail: 'oferta de lançamento',
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
              const Text(
                'O aplicativo local continuará gratuito e open source. '
                'A cobrança será ativada somente após integração oficial.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 12),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07140D), Color(0xFF08743E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F9D58),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD54F),
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entitlement.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  entitlement.isActive
                      ? 'Seus recursos Premium estão ativos.'
                      : 'Mais automação, nuvem e inteligência financeira.',
                  style: const TextStyle(color: Color(0xFFC8EED8)),
                ),
              ],
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
            ? const BorderSide(color: AppColors.primary, width: 2)
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
            Text(detail, style: const TextStyle(color: AppColors.muted)),
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
        'Backup automático, múltiplos dispositivos e histórico.'
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
                  backgroundColor: AppColors.primary.withValues(alpha: .14),
                  child: Icon(groups[index].$1, color: AppColors.primary),
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
