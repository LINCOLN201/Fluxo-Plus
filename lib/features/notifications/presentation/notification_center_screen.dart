import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/update/app_update.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/new_transaction_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({
    super.key,
    required this.repository,
    required this.availableUpdate,
    required this.onOpenUpdate,
    required this.onChanged,
  });

  final TransactionRepository repository;
  final AppUpdate? availableUpdate;
  final VoidCallback onOpenUpdate;
  final VoidCallback onChanged;

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<List<TransactionRecord>> _alerts;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _alerts = widget.repository.dueAlerts();

  Future<void> _markPaid(TransactionRecord record) async {
    await widget.repository.setPaid(record.transaction.id!, true);
    widget.onChanged();
    setState(_reload);
  }

  Future<void> _open(TransactionRecord record) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewTransactionScreen(
          repository: widget.repository,
          transaction: record.transaction,
        ),
      ),
    );
    if (changed == true) {
      widget.onChanged();
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seus avisos')),
      body: FutureBuilder<List<TransactionRecord>>(
        future: _alerts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final alerts = snapshot.requireData;
          final hasUpdate = widget.availableUpdate != null;
          if (alerts.isEmpty && !hasUpdate) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: context.colors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tudo em dia por aqui',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Quando uma conta estiver perto do vencimento, '
                      'ela aparecerá aqui.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (hasUpdate) ...[
                Card(
                  child: ListTile(
                    onTap: widget.onOpenUpdate,
                    leading: CircleAvatar(
                      backgroundColor: context.colors.primary,
                      child: Icon(Icons.system_update_rounded,
                          color: context.colors.onPrimary),
                    ),
                    title: Text(
                      'Fluxo+ ${widget.availableUpdate!.version} disponível',
                    ),
                    subtitle: const Text('Toque para conhecer e instalar.'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (alerts.isNotEmpty) ...[
                Text(
                  'Contas que pedem atenção',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                const Text('Ordenadas pelo vencimento mais próximo.'),
                const SizedBox(height: 12),
                ...alerts.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _AlertCard(
                      record: record,
                      onOpen: () => _open(record),
                      onPaid: () => _markPaid(record),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.record,
    required this.onOpen,
    required this.onPaid,
  });

  final TransactionRecord record;
  final VoidCallback onOpen;
  final VoidCallback onPaid;

  @override
  Widget build(BuildContext context) {
    final transaction = record.transaction;
    final today = DateUtils.dateOnly(DateTime.now());
    final due = DateUtils.dateOnly(transaction.date);
    final difference = due.difference(today).inDays;
    final overdue = difference < 0;
    final label = overdue
        ? 'Vencida há ${difference.abs()} dia${difference.abs() == 1 ? '' : 's'}'
        : difference == 0
            ? 'Vence hoje'
            : 'Vence em $difference dia${difference == 1 ? '' : 's'}';
    final statusColor =
        overdue ? context.colors.expense : context.colors.warning;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(record.categoryColor).withValues(
                  alpha: .15,
                ),
                child: Icon(
                  CategoryIcons.resolve(record.categoryIcon),
                  color: Color(record.categoryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$label • ${AppFormatters.date(transaction.date)}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      AppFormatters.currency(transaction.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onPaid,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Pago'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
