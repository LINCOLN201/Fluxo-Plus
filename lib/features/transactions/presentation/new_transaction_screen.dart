import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/finance_transaction.dart';
import '../data/transaction_repository.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({
    super.key,
    required this.repository,
    this.transaction,
  });

  final TransactionRepository repository;
  final FinanceTransaction? transaction;

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  TransactionType _type = TransactionType.expense;
  DateTime _date = DateTime.now();
  List<Account> _accounts = const [];
  List<Category> _categories = const [];
  int? _accountId;
  int? _categoryId;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      _type = transaction.type;
      _date = transaction.date;
      _amountController.text =
          transaction.amount.toStringAsFixed(2).replaceAll('.', ',');
      _descriptionController.text = transaction.description;
    }
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final accounts = await widget.repository.getAccounts();
    final categories = await widget.repository.getCategories(_type);
    if (!mounted) return;
    setState(() {
      _accounts = accounts;
      _categories = categories;
      _accountId = widget.transaction?.accountId ??
          (accounts.isEmpty ? null : accounts.first.id);
      _categoryId = widget.transaction?.categoryId ??
          (categories.isEmpty ? null : categories.first.id);
      _loading = false;
    });
  }

  Future<void> _changeType(TransactionType type) async {
    setState(() {
      _type = type;
      _loading = true;
    });
    final categories = await widget.repository.getCategories(type);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _categoryId = categories.isEmpty ? null : categories.first.id;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final transaction = FinanceTransaction(
        id: widget.transaction?.id,
        type: _type,
        amount: AppFormatters.parseCurrency(_amountController.text)!,
        categoryId: _categoryId!,
        accountId: _accountId!,
        date: _date,
        description: _descriptionController.text.trim(),
        createdAt: widget.transaction?.createdAt ?? DateTime.now(),
      );
      if (widget.transaction == null) {
        await widget.repository.create(transaction);
      } else {
        await widget.repository.update(transaction);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.transaction == null ? 'Nova transação' : 'Editar transação',
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<TransactionType>(
                            segments: const [
                              ButtonSegment(
                                value: TransactionType.income,
                                icon: Icon(Icons.arrow_downward_rounded),
                                label: Text('Receita'),
                              ),
                              ButtonSegment(
                                value: TransactionType.expense,
                                icon: Icon(Icons.arrow_upward_rounded),
                                label: Text('Despesa'),
                              ),
                            ],
                            selected: {_type},
                            onSelectionChanged: (value) =>
                                _changeType(value.first),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Valor',
                              prefixText: r'R$ ',
                              prefixIcon: Icon(Icons.attach_money_rounded),
                            ),
                            validator: (value) {
                              final amount =
                                  AppFormatters.parseCurrency(value ?? '');
                              if (amount == null || amount <= 0) {
                                return 'Informe um valor maior que zero';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                            items: _categories
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _categoryId = value),
                            validator: (value) => value == null
                                ? 'Selecione uma categoria'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            initialValue: _accountId,
                            decoration: const InputDecoration(
                              labelText: 'Conta',
                              prefixIcon:
                                  Icon(Icons.account_balance_wallet_outlined),
                            ),
                            items: _accounts
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _accountId = value),
                            validator: (value) =>
                                value == null ? 'Selecione uma conta' : null,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(14),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Data',
                                prefixIcon: Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(AppFormatters.date(_date)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLength: 120,
                            decoration: const InputDecoration(
                              labelText: 'Descrição (opcional)',
                              prefixIcon: Icon(Icons.notes_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: _type == TransactionType.income
                                  ? AppColors.primary
                                  : AppColors.expense,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: _saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              widget.transaction == null
                                  ? 'Salvar transação'
                                  : 'Salvar alterações',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
