import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
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
  });

  final TransactionRepository repository;
  final VoidCallback onChanged;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _month = DateTime.now();
  TransactionType? _type;
  int? _categoryId;
  List<Category> _categories = const [];
  late Future<List<TransactionRecord>> _records;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _records = widget.repository.list(
      month: _month,
      type: _type,
      categoryId: _categoryId,
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

  Future<void> _delete(TransactionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir transação?'),
        content: Text(
          '“${record.transaction.description.isEmpty ? record.categoryName : record.transaction.description}” será removida definitivamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final value = await showDatePicker(
                      context: context,
                      initialDate: _month,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (value != null) {
                      setState(() {
                        _month = value;
                        _load();
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    DateFormat('MMMM / yyyy', 'pt_BR').format(_month),
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<TransactionType?>(
                  value: _type,
                  hint: const Text('Todos os tipos'),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('Todos os tipos')),
                    DropdownMenuItem(
                      value: TransactionType.income,
                      child: Text('Receitas'),
                    ),
                    DropdownMenuItem(
                      value: TransactionType.expense,
                      child: Text('Despesas'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _type = value;
                    _categoryId = null;
                    _load();
                  }),
                ),
                const SizedBox(width: 16),
                DropdownButton<int?>(
                  value: _categoryId,
                  hint: const Text('Todas as categorias'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todas as categorias'),
                    ),
                    ..._categories
                        .where((item) => _type == null || item.type == _type)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() {
                    _categoryId = value;
                    _load();
                  }),
                ),
              ],
            ),
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
                    message: 'Não há lançamentos para os filtros selecionados.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    final transaction = record.transaction;
                    final income = transaction.type == TransactionType.income;
                    final color =
                        income ? AppColors.primary : AppColors.expense;
                    return Card(
                      child: ListTile(
                        onTap: () => _open(record),
                        leading: CircleAvatar(
                          backgroundColor: Color(record.categoryColor)
                              .withValues(alpha: .15),
                          child: Icon(
                            income
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: color,
                          ),
                        ),
                        title: Text(
                          transaction.description.isEmpty
                              ? record.categoryName
                              : transaction.description,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${record.categoryName} • ${record.accountName} • ${AppFormatters.date(transaction.date)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${income ? '+' : '-'} ${AppFormatters.currency(transaction.amount)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) => value == 'edit'
                                  ? _open(record)
                                  : _delete(record),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Editar'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Excluir'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
