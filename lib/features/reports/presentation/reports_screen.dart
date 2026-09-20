import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/formatters.dart';
import '../data/report_repository.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final ReportRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _month = DateTime.now();
  late Future<MonthlyReport> _report;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _report = widget.repository.load(_month);

  void _moveMonth(int offset) {
    setState(() {
      _month = DateTime(_month.year, _month.month + offset);
      _reload();
    });
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<MonthlyReport>(
        future: _report,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final report = snapshot.requireData;
          return RefreshIndicator(
            onRefresh: () async {
              setState(_reload);
              await _report;
            },
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 900
                      ? (constraints.maxWidth - 860) / 2
                      : 16,
                  vertical: 10,
                ),
                children: [
                  _MonthNavigator(
                    month: _month,
                    canGoForward: !_isCurrentMonth,
                    onPrevious: () => _moveMonth(-1),
                    onNext: () => _moveMonth(1),
                  ),
                  const SizedBox(height: 16),
                  _ResultHero(report: report),
                  const SizedBox(height: 12),
                  _MetricGrid(report: report),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Receitas e despesas',
                    subtitle: 'Comparação do que entrou e saiu no período',
                  ),
                  const SizedBox(height: 10),
                  _ComparisonCard(report: report),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Para onde foi o dinheiro',
                    subtitle: report.categories.isEmpty
                        ? 'Ainda não há despesas neste mês'
                        : '${report.categories.length} categorias com lançamentos',
                  ),
                  const SizedBox(height: 10),
                  _CategoryCard(report: report),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.month,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Mês anterior',
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                DateFormat('MMMM', 'pt_BR').format(month),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${month.year}',
                style: TextStyle(color: context.colors.textMuted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: canGoForward ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Próximo mês',
        ),
      ],
    );
  }
}

class _ResultHero extends StatelessWidget {
  const _ResultHero({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final positive = report.result >= 0;
    final rate = report.savingsRate;
    final semantic = positive ? context.colors.income : context.colors.expense;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: semantic.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resultado previsto do mês',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
              Icon(
                positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: semantic,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.currency(report.result),
            style: TextStyle(
              color: semantic,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            positive
                ? rate > 0
                    ? 'Você preservou ${(rate * 100).toStringAsFixed(0)}% das receitas previstas.'
                    : 'Receitas e despesas estão equilibradas.'
                : 'Faltam ${AppFormatters.currency(report.result.abs())} para equilibrar o mês.',
            style: TextStyle(color: context.colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        final metrics = [
          (
            'Receitas',
            report.income,
            context.colors.income,
            Icons.south_west_rounded,
            '${AppFormatters.currency(report.receivedIncome)} recebidos'
          ),
          (
            'Despesas',
            report.expense,
            context.colors.expense,
            Icons.north_east_rounded,
            '${AppFormatters.currency(report.paidExpense)} pagos'
          ),
          (
            'A pagar',
            report.pendingExpense,
            context.colors.warning,
            Icons.schedule_rounded,
            '${report.transactionCount} lançamentos no mês'
          ),
        ];
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _MetricCard(
                    label: item.$1,
                    value: item.$2,
                    color: item.$3,
                    icon: item.$4,
                    detail: item.$5,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.detail,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(color: context.colors.textMuted)),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                AppFormatters.currency(value),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              detail,
              maxLines: 2,
              style: TextStyle(fontSize: 10, color: context.colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        Text(subtitle, style: TextStyle(color: context.colors.textMuted)),
      ],
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final max = report.income > report.expense ? report.income : report.expense;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _ComparisonRow(
              label: 'Receitas',
              value: report.income,
              max: max,
              color: context.colors.income,
            ),
            const SizedBox(height: 20),
            _ComparisonRow(
              label: 'Despesas',
              value: report.expense,
              max: max,
              color: context.colors.expense,
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              AppFormatters.currency(value),
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: max == 0 ? 0 : value / max,
          minHeight: 12,
          borderRadius: BorderRadius.circular(8),
          color: color,
          backgroundColor: color.withValues(alpha: .12),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: report.categories.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: Text('Sem despesas neste período')),
              )
            : Column(
                children: report.categories.map((item) {
                  final percentage =
                      report.expense == 0 ? 0.0 : item.amount / report.expense;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Color(item.color).withValues(alpha: .14),
                              child: Icon(
                                CategoryIcons.resolve(item.icon),
                                size: 18,
                                color: Color(item.color),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(0)}% das despesas',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.currency(item.amount),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentage,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(8),
                          color: Color(item.color),
                          backgroundColor:
                              Color(item.color).withValues(alpha: .10),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
