import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/dashboard_repository.dart';
import '../domain/dashboard_summary.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.repository,
    required this.onAddTransaction,
  });

  final DashboardRepository repository;
  final VoidCallback onAddTransaction;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = widget.repository.load(DateTime.now());
  }

  Future<void> _refresh() async {
    setState(() => _summary = widget.repository.load(DateTime.now()));
    await _summary;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Não foi possível carregar',
            message: snapshot.error.toString(),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final dark = Theme.of(context).brightness == Brightness.dark;
            return constraints.maxWidth < 700
                ? _MobileDashboard(
                    summary: snapshot.requireData,
                    onRefresh: _refresh,
                    dark: dark,
                  )
                : _DesktopDashboard(
                    summary: snapshot.requireData,
                    onRefresh: _refresh,
                    onAddTransaction: widget.onAddTransaction,
                    dark: dark,
                  );
          },
        );
      },
    );
  }
}

class _DesktopDashboard extends StatelessWidget {
  const _DesktopDashboard({
    required this.summary,
    required this.onRefresh,
    required this.onAddTransaction,
    required this.dark,
  });

  final DashboardSummary summary;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddTransaction;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dark ? const Color(0xFF0D1820) : const Color(0xFFF6F8FA),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dashboard',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontSize: 27),
                          ),
                          const SizedBox(height: 4),
                          const Text('Visão geral da sua vida financeira'),
                        ],
                      ),
                    ),
                    _MonthButton(),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onAddTransaction,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nova transação'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisExtent: 132,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate([
                  _MetricCard(
                    dark: dark,
                    label: 'Saldo total',
                    value: summary.balance,
                    color: AppColors.primaryDark,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  _MetricCard(
                    dark: dark,
                    label: 'Receitas',
                    value: summary.monthIncome,
                    color: AppColors.primary,
                    icon: Icons.south_west_rounded,
                  ),
                  _MetricCard(
                    dark: dark,
                    label: 'Despesas',
                    value: summary.monthExpense,
                    color: AppColors.expense,
                    icon: Icons.north_east_rounded,
                  ),
                  _MetricCard(
                    dark: dark,
                    label: 'Economia',
                    value: summary.savings,
                    color: summary.savings >= 0
                        ? AppColors.primary
                        : AppColors.warning,
                    icon: Icons.savings_outlined,
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 310,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _Panel(
                          dark: dark,
                          title: 'Evolução mensal',
                          child: _FlowChart(items: summary.monthlyFlow),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: _Panel(
                          dark: dark,
                          title: 'Despesas por categoria',
                          child: _CategoryChart(
                            items: summary.categorySpending,
                            dark: dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 350,
                  child: _Panel(
                    dark: dark,
                    title: 'Últimas transações',
                    child: SingleChildScrollView(
                      child: _TransactionList(
                        items: summary.recentTransactions,
                        desktop: true,
                        dark: dark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.summary,
    required this.onRefresh,
    required this.dark,
  });

  final DashboardSummary summary;
  final Future<void> Function() onRefresh;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: dark ? const Color(0xFF0D1820) : const Color(0xFFF6F8FA),
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Olá! 👋',
                          style: TextStyle(
                            color: dark ? Colors.white : AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Tenha um ótimo dia!',
                          style: TextStyle(color: Color(0xFF91A0AA)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.notifications_none_rounded,
                    color: dark ? Colors.white : AppColors.text,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF08743E), AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D0F9D58),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saldo total',
                      style: TextStyle(color: Color(0xFFD9F5E4)),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      AppFormatters.currency(summary.balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seus dados estão seguros neste dispositivo',
                      style: TextStyle(
                        color: Color(0xFFC4F0D5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MobileMetric(
                      dark: dark,
                      label: 'Receitas',
                      value: summary.monthIncome,
                      color: AppColors.primary,
                      icon: Icons.arrow_upward_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MobileMetric(
                      dark: dark,
                      label: 'Despesas',
                      value: summary.monthExpense,
                      color: AppColors.expense,
                      icon: Icons.arrow_downward_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _MobileSectionTitle(
                title: 'Despesas por categoria',
                dark: dark,
              ),
              const SizedBox(height: 12),
              Container(
                height: 205,
                padding: const EdgeInsets.all(16),
                decoration:
                    dark ? _darkDecoration() : _lightDecoration(dark: false),
                child: _CategoryChart(
                  items: summary.categorySpending,
                  dark: dark,
                ),
              ),
              const SizedBox(height: 22),
              _MobileSectionTitle(
                title: 'Transações recentes',
                dark: dark,
              ),
              const SizedBox(height: 10),
              _TransactionList(
                items: summary.recentTransactions,
                desktop: false,
                dark: dark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.dark,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _lightDecoration(dark: dark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const Spacer(),
          Text(
            AppFormatters.currency(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.text,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value >= 0 ? '● Atualizado agora' : '● Atenção ao orçamento',
            style: TextStyle(
              color: value >= 0 ? AppColors.primary : AppColors.expense,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileMetric extends StatelessWidget {
  const _MobileMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.dark,
  });

  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111E27) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              AppFormatters.currency(value),
              style: TextStyle(
                color: dark ? Colors.white : AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    required this.dark,
  });

  final String title;
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _lightDecoration(dark: dark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _FlowChart extends StatelessWidget {
  const _FlowChart({required this.items});

  final List<MonthlyFlow> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _LegendDot(color: AppColors.primary, text: 'Receitas'),
            SizedBox(width: 14),
            _LegendDot(color: AppColors.expense, text: 'Despesas'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: CustomPaint(
            painter: _FlowPainter(items),
            child: const SizedBox.expand(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items
              .map(
                (item) => Text(
                  DateFormat('MMM', 'pt_BR').format(item.month),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _FlowPainter extends CustomPainter {
  _FlowPainter(this.items);

  final List<MonthlyFlow> items;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8EDF2)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final maxValue = items.fold<double>(
      1,
      (max, item) => math.max(max, math.max(item.income, item.expense)),
    );
    _drawLine(canvas, size, maxValue, (item) => item.income, AppColors.primary);
    _drawLine(
        canvas, size, maxValue, (item) => item.expense, AppColors.expense);
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    double maxValue,
    double Function(MonthlyFlow) value,
    Color color,
  ) {
    final path = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < items.length; index++) {
      final x = size.width * index / math.max(1, items.length - 1);
      final y = size.height - (value(items[index]) / maxValue * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = color);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlowPainter oldDelegate) =>
      oldDelegate.items != items;
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.items, this.dark = false});

  final List<CategorySpending> items;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'Sem despesas neste mês',
          style: TextStyle(
              color: dark ? const Color(0xFF91A0AA) : AppColors.muted),
        ),
      );
    }
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: _DonutPainter(items)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.map((item) {
              final percent = total == 0 ? 0 : item.amount / total * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(item.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: dark ? Colors.white : AppColors.text,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: dark ? const Color(0xFF91A0AA) : AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.items);

  final List<CategorySpending> items;

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    var start = -math.pi / 2;
    final rect = Offset.zero & size;
    final stroke = size.shortestSide * .22;
    for (final item in items) {
      final sweep = total == 0 ? 0.0 : item.amount / total * math.pi * 2;
      canvas.drawArc(
        rect.deflate(stroke / 2),
        start,
        sweep,
        false,
        Paint()
          ..color = Color(item.color)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.items != items;
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.items,
    required this.desktop,
    required this.dark,
  });

  final List<TransactionListItem> items;
  final bool desktop;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Text(
            'Adicione sua primeira transação',
            style: TextStyle(
              color: dark ? const Color(0xFF91A0AA) : AppColors.muted,
            ),
          ),
        ),
      );
    }
    return Column(
      children: items.map((item) {
        final income = item.type == TransactionType.income;
        final color = income ? AppColors.primary : AppColors.expense;
        return Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 8 : 12,
            vertical: 10,
          ),
          decoration: desktop
              ? null
              : dark
                  ? _darkDecoration()
                  : _lightDecoration(dark: false),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: .15),
                child: Icon(
                  income ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description.isEmpty
                          ? item.categoryName
                          : item.description,
                      style: TextStyle(
                        color: dark ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      item.categoryName,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (desktop)
                Expanded(
                  child: Text(
                    AppFormatters.date(item.date),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ),
              Text(
                '${income ? '+' : '-'} ${AppFormatters.currency(item.amount)}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.calendar_month_outlined, size: 17),
      label: Text(DateFormat('MMMM / yyyy', 'pt_BR').format(DateTime.now())),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        side: const BorderSide(color: Color(0xFFE0E6EB)),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

class _MobileSectionTitle extends StatelessWidget {
  const _MobileSectionTitle({required this.title, required this.dark});

  final String title;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: dark ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const Text(
          'Ver todas',
          style: TextStyle(color: AppColors.primary, fontSize: 11),
        ),
      ],
    );
  }
}

BoxDecoration _lightDecoration({required bool dark}) => BoxDecoration(
      color: dark ? const Color(0xFF111E27) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: dark ? const Color(0xFF26343D) : const Color(0xFFE8EDF2),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    );

BoxDecoration _darkDecoration() => BoxDecoration(
      color: const Color(0xFF111E27),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF22313B)),
    );
