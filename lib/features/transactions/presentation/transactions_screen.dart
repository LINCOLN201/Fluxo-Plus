import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/transaction_repository.dart';
import 'new_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.repository,
    required this.onChanged,
    this.initialType,
  });

  final TransactionRepository repository;
  final VoidCallback onChanged;
  final TransactionType? initialType;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _month = DateTime.now();
  TransactionType? _type;
  int? _categoryId;
  PaymentFilter _payment = PaymentFilter.all;
  List<Category> _categories = const [];
  late Future<List<TransactionRecord>> _records;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _load();
  }

  void _load() {
    _records = widget.repository.list(
      month: _month,
      type: _type,
      categoryId: _categoryId,
      payment: _payment,
    );
    widget.repository.getAllCategories().then((value) {
      if (mounted) setState(() => _categories = value);
    });
  }

  void _refresh() => setState(_load);

  Future<void> _open([TransactionRecord? record]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewTransactionScreen(
          repository: widget.repository,
          transaction: record?.transaction,
        ),
      ),
    );
    if (changed == true) {
      widget.onChanged();
      _refresh();
    }
  }

  Future<void> _togglePaid(TransactionRecord record) async {
    await widget.repository.setPaid(
      record.transaction.id!,
      !record.transaction.isPaid,
    );
    widget.onChanged();
    _refresh();
  }

  Future<void> _delete(TransactionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: Text(
          '“${record.transaction.name}” será removida definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.expense,
              foregroundColor: context.colors.onPrimary,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(record.transaction.id!);
    widget.onChanged();
    _refresh();
  }

  Future<void> _selectMonth() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('pt', 'BR'),
    );
    if (value == null) return;
    setState(() {
      _month = value;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transações'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _open,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nova'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _Filters(
            month: _month,
            type: _type,
            categoryId: _categoryId,
            payment: _payment,
            categories: _categories,
            onMonth: _selectMonth,
            onType: (value) => setState(() {
              _type = value;
              _categoryId = null;
              _load();
            }),
            onCategory: (value) => setState(() {
              _categoryId = value;
              _load();
            }),
            onPayment: (value) => setState(() {
              _payment = value;
              _load();
            }),
          ),
          Expanded(
            child: FutureBuilder<List<TransactionRecord>>(
              future: _records,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.requireData;
                if (records.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhuma transação',
                    message: 'Ajuste os filtros ou adicione um lançamento.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _TransactionCard(
                    record: records[index],
                    onOpen: () => _open(records[index]),
                    onTogglePaid: () => _togglePaid(records[index]),
                    onDelete: () => _delete(records[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.month,
    required this.type,
    required this.categoryId,
    required this.payment,
    required this.categories,
    required this.onMonth,
    required this.onType,
    required this.onCategory,
    required this.onPayment,
  });

  final DateTime month;
  final TransactionType? type;
  final int? categoryId;
  final PaymentFilter payment;
  final List<Category> categories;
  final VoidCallback onMonth;
  final ValueChanged<TransactionType?> onType;
  final ValueChanged<int?> onCategory;
  final ValueChanged<PaymentFilter> onPayment;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: onMonth,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(DateFormat('MMM / yyyy', 'pt_BR').format(month)),
          ),
          const SizedBox(width: 8),
          _FilterMenu<String>(
            value: type?.name ?? 'all',
            label: type == null
                ? 'Todos'
                : type == TransactionType.income
                    ? 'Receitas'
                    : 'Despesas',
            items: const [
              ('all', 'Todos'),
              ('income', 'Receitas'),
              ('expense', 'Despesas'),
            ],
            onChanged: (value) => onType(
              value == 'all' ? null : TransactionType.values.byName(value),
            ),
          ),
          const SizedBox(width: 8),
          _FilterMenu<PaymentFilter>(
            value: payment,
            label: switch (payment) {
              PaymentFilter.all => 'Todos os status',
              PaymentFilter.pending => 'Pendentes',
              PaymentFilter.paid => 'Concluídos',
            },
            items: const [
              (PaymentFilter.all, 'Todos os status'),
              (PaymentFilter.pending, 'Pendentes'),
              (PaymentFilter.paid, 'Concluídos'),
            ],
            onChanged: onPayment,
          ),
          const SizedBox(width: 8),
          _FilterMenu<int>(
            value: categoryId ?? -1,
            label: categoryId == null
                ? 'Categorias'
                : categories.firstWhere((item) => item.id == categoryId).name,
            items: [
              const (-1, 'Categorias'),
              ...categories
                  .where((item) => type == null || item.type == type)
                  .map((item) => (item.id!, item.name)),
            ],
            onChanged: (value) => onCategory(value == -1 ? null : value),
          ),
        ],
      ),
    );
  }
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final String label;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<T>(
              value: item.$1,
              child: Text(item.$2),
            ),
          )
          .toList(),
      child: Chip(
        label: Text(label),
        avatar: const Icon(Icons.tune_rounded, size: 17),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.record,
    required this.onOpen,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final TransactionRecord record;
  final VoidCallback onOpen;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final transaction = record.transaction;
    final income = transaction.type == TransactionType.income;
    final color = income ? context.colors.income : context.colors.expense;
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDate = DateUtils.dateOnly(transaction.date);
    final overdue = !transaction.isPaid && dueDate.isBefore(today);
    final installment = transaction.installmentCount > 1
        ? ' • ${transaction.installmentNumber}/${transaction.installmentCount}'
        : '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Color(record.categoryColor).withValues(alpha: .15),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${record.categoryName} • ${record.accountName}$installment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _StatusPill(
                          label: transaction.isPaid
                              ? (income ? 'Recebido' : 'Pago')
                              : overdue
                                  ? 'Vencido'
                                  : 'Pendente',
                          color: transaction.isPaid
                              ? context.colors.income
                              : overdue
                                  ? context.colors.expense
                                  : context.colors.warning,
                        ),
                        Text(
                          '${income ? 'Data' : 'Vence'} ${AppFormatters.date(transaction.date)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${income ? '+' : '-'} ${AppFormatters.currency(transaction.amount)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Ações',
                    onSelected: (value) {
                      if (value == 'paid') {
                        onTogglePaid();
                      } else if (value == 'edit') {
                        onOpen();
                      } else {
                        onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'paid',
                        child: Text(
                          transaction.isPaid
                              ? 'Marcar como pendente'
                              : income
                                  ? 'Marcar recebido'
                                  : 'Marcar pago',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Excluir'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
