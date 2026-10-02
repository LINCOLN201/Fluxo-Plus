import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/finance_transaction.dart';
import '../../transactions/data/transaction_repository.dart';
import '../streaming_catalog.dart';

/// Assinaturas (streamers, música, nuvem) que a pessoa paga todo mês — a
/// mesma engrenagem de lançamentos recorrentes de [TransactionRepository],
/// só com uma tela dedicada pra dar uma visão só do que costuma passar
/// despercebido no meio das outras transações.
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({
    super.key,
    required this.repository,
    required this.onChanged,
  });

  final TransactionRepository repository;
  final VoidCallback onChanged;

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  late Future<List<SubscriptionSummary>> _subscriptions;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _subscriptions = widget.repository.listActiveSubscriptions();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _subscriptions;
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _AddSubscriptionSheet(repository: widget.repository),
    );
    if (added == true && mounted) {
      await _refresh();
      widget.onChanged();
    }
  }

  Future<void> _cancel(SubscriptionSummary subscription) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar assinatura?'),
        content: Text(
          'As próximas cobranças de "${subscription.description}" '
          'deixam de ser lançadas. O histórico já pago continua registrado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar assinatura'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.repository.stopRecurring(subscription.recurringGroup);
    await _refresh();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assinaturas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Adicionar'),
      ),
      body: FutureBuilder<List<SubscriptionSummary>>(
        future: _subscriptions,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40),
                  const SizedBox(height: 12),
                  const Text('Erro ao carregar assinaturas.'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final subscriptions = snapshot.data!;
          final total =
              subscriptions.fold<double>(0, (sum, item) => sum + item.amount);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Card(
                  color: context.colors.primary.withValues(alpha: .1),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total mensal em assinaturas',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppFormatters.currency(total),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: context.colors.primary,
                          ),
                        ),
                        if (subscriptions.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${subscriptions.length} assinatura${subscriptions.length == 1 ? '' : 's'} ativa${subscriptions.length == 1 ? '' : 's'}',
                            style: TextStyle(color: context.colors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (subscriptions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 48,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma assinatura cadastrada ainda.',
                          style: TextStyle(color: context.colors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Toque em "Adicionar" para começar a acompanhar '
                          'quanto você paga por mês em streaming e outros '
                          'serviços.',
                          style: TextStyle(color: context.colors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  for (final subscription in subscriptions)
                    _SubscriptionTile(
                      subscription: subscription,
                      onCancel: () => _cancel(subscription),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  const _SubscriptionTile({
    required this.subscription,
    required this.onCancel,
  });

  final SubscriptionSummary subscription;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final service = StreamingCatalog.match(subscription.description);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        leading: CircleAvatar(
          backgroundColor: service.color.withValues(alpha: .16),
          child: Icon(service.icon, color: service.color),
        ),
        title: Text(
          subscription.description,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'Próxima cobrança: ${AppFormatters.date(subscription.nextDate)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              AppFormatters.currency(subscription.amount),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 28),
                foregroundColor: context.colors.expense,
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddSubscriptionSheet extends StatefulWidget {
  const _AddSubscriptionSheet({required this.repository});

  final TransactionRepository repository;

  @override
  State<_AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<_AddSubscriptionSheet> {
  final _key = GlobalKey<FormState>();
  final _customName = TextEditingController();
  final _amount = TextEditingController();
  StreamingService _selected = StreamingCatalog.services.first;
  DateTime _dueDate = DateTime.now();
  bool _saving = false;

  bool get _isCustom => _selected.name == 'Outro';

  @override
  void dispose() {
    _customName.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Data da próxima cobrança',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final categories =
          await widget.repository.getCategories(TransactionType.expense);
      final accounts = await widget.repository.getAccounts();
      if (!mounted) return;
      if (categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crie ao menos uma categoria de despesa primeiro.'),
          ),
        );
        return;
      }
      if (accounts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crie ao menos uma conta primeiro.')),
        );
        return;
      }
      final category = categories.firstWhere(
        (item) => item.isSubscription,
        orElse: () => categories.firstWhere(
          (item) => item.name == 'Assinaturas',
          orElse: () => categories.first,
        ),
      );
      final name = _isCustom ? _customName.text.trim() : _selected.name;
      final now = DateTime.now();
      await widget.repository.createRecurring(
        FinanceTransaction(
          type: TransactionType.expense,
          amount: AppFormatters.parseCurrency(_amount.text)!,
          categoryId: category.id!,
          accountId: accounts.first.id!,
          date: _dueDate,
          description: name,
          createdAt: now,
          isPaid: false,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova assinatura',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final service in StreamingCatalog.services)
                  ChoiceChip(
                    label: Text(service.name),
                    avatar: Icon(service.icon, size: 18, color: service.color),
                    selected: _selected.name == service.name,
                    onSelected: (_) => setState(() => _selected = service),
                  ),
              ],
            ),
            if (_isCustom) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _customName,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome do serviço'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome'
                    : null,
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor mensal'),
              validator: (value) {
                final amount = AppFormatters.parseCurrency(value ?? '');
                return amount == null || amount < 0.01
                    ? 'Informe um valor válido'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_rounded),
              title: const Text('Próxima cobrança'),
              subtitle: Text(AppFormatters.date(_dueDate)),
              trailing: TextButton(
                onPressed: _pickDueDate,
                child: const Text('Alterar'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Salvando...' : 'Salvar assinatura'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
