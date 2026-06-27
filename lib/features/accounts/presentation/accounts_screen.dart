import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/account.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/account_repository.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key, required this.repository});

  final AccountRepository repository;

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late Future<List<AccountBalance>> _accounts;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _accounts = widget.repository.list();

  Future<void> _edit([Account? account]) async {
    final name = TextEditingController(text: account?.name);
    final balance = TextEditingController(
      text: account?.initialBalance.toStringAsFixed(2).replaceAll('.', ','),
    );
    final key = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account == null ? 'Nova conta' : 'Editar conta'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o nome'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: balance,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Saldo inicial'),
                validator: (value) =>
                    AppFormatters.parseCurrency(value ?? '') == null
                        ? 'Informe um valor válido'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    await widget.repository.save(
      Account(
        id: account?.id,
        name: name.text.trim(),
        initialBalance: AppFormatters.parseCurrency(balance.text)!,
        createdAt: account?.createdAt ?? DateTime.now(),
      ),
    );
    setState(_reload);
  }

  Future<void> _delete(AccountBalance item) async {
    final deleted = await widget.repository.delete(item.account.id!);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Esta conta possui transações e não pode ser excluída.'),
        ),
      );
    } else {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contas'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.add),
              label: const Text('Nova conta'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AccountBalance>>(
        future: _accounts,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.requireData;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nenhuma conta',
              message: 'Crie uma conta para organizar seus lançamentos.',
            );
          }
          final total =
              items.fold<double>(0, (sum, item) => sum + item.balance);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                color: AppColors.primaryDark,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo em todas as contas',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppFormatters.currency(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ...items.map(
                (item) => Card(
                  child: ListTile(
                    onTap: () => _edit(item.account),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE4F7EB),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      item.account.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${item.transactionCount} transações'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.currency(item.balance),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => value == 'edit'
                              ? _edit(item.account)
                              : _delete(item),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
