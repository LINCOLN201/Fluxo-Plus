import 'package:flutter/material.dart';

import '../../../core/premium/premium_entitlement.dart';
import '../../../core/premium/premium_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_palette.dart';
import '../../../core/utils/category_icons.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
    required this.repository,
    required this.premiumService,
  });

  final CategoryRepository repository;
  final PremiumService premiumService;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<CategoryUsage>> _categories;
  PremiumEntitlement _entitlement = const PremiumEntitlement.free();

  @override
  void initState() {
    super.initState();
    _reload();
    widget.premiumService.load().then((value) {
      if (mounted) setState(() => _entitlement = value);
    });
  }

  void _reload() => _categories = widget.repository.list();

  Future<void> _edit([Category? category]) async {
    final name = TextEditingController(text: category?.name);
    var type = category?.type ?? TransactionType.expense;
    var icon = category?.icon ?? 'category';
    int? color = category?.color;
    final colorsUnlocked = _entitlement.allows(PremiumFeature.customColors);
    final key = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Nova categoria' : 'Editar categoria'),
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
                const SizedBox(height: 14),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Receita'),
                    ),
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Despesa'),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (value) =>
                      setDialogState(() => type = value.first),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: icon,
                  decoration: const InputDecoration(
                    labelText: 'Ícone',
                    prefixIcon: Icon(Icons.auto_awesome_outlined),
                  ),
                  items: CategoryIcons.choices
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.$1,
                          child: Row(
                            children: [
                              Icon(item.$2, size: 20),
                              const SizedBox(width: 10),
                              Text(item.$3),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => icon = value ?? 'category'),
                ),
                const SizedBox(height: 16),
                _ColorPicker(
                  selected: color,
                  unlocked: colorsUnlocked,
                  onSelected: (value) => setDialogState(() => color = value),
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
      ),
    );
    if (saved != true) return;
    await widget.repository.save(
      Category(
        id: category?.id,
        name: name.text.trim(),
        type: type,
        icon: icon,
        color: color ??
            (type == TransactionType.income
                // Stored in the DB: must be theme-independent (fixed values).
                ? AppColors.light.income.toARGB32()
                : AppColors.light.expense.toARGB32()),
        isDefault: category?.isDefault ?? false,
      ),
    );
    setState(_reload);
  }

  Future<void> _delete(CategoryUsage usage) async {
    final deleted = await widget.repository.delete(usage.category.id!);
    if (!mounted) return;
    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('A categoria possui transações e não pode ser excluída.'),
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
        title: const Text('Categorias'),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: _edit,
              icon: const Icon(Icons.add),
              label: const Text('Nova'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<CategoryUsage>>(
        future: _categories,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.requireData;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'Nenhuma categoria',
              message: 'Crie categorias para classificar seus lançamentos.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final usage = items[index];
              final item = usage.category;
              return Card(
                child: ListTile(
                  onTap: () => _edit(item),
                  leading: CircleAvatar(
                    backgroundColor: Color(item.color).withValues(alpha: .16),
                    child: Icon(
                      CategoryIcons.resolve(item.icon),
                      color: Color(item.color),
                    ),
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${item.type == TransactionType.income ? 'Receita' : 'Despesa'} • ${usage.usageCount} usos${item.isDefault ? ' • Padrão' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        value == 'edit' ? _edit(item) : _delete(usage),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({
    required this.selected,
    required this.unlocked,
    required this.onSelected,
  });

  final int? selected;
  final bool unlocked;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Cor', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.colors.border),
              ),
              child: Text(
                'Premium',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in CategoryPalette.premium)
              Semantics(
                button: true,
                selected: value == selected,
                label: 'Cor da categoria',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: unlocked
                      ? () => onSelected(value)
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'A paleta de cores faz parte do Fluxo+ Premium.',
                              ),
                            ),
                          ),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(value).withValues(alpha: unlocked ? 1 : .35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: value == selected
                            ? context.colors.textPrimary
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: unlocked
                        ? null
                        : const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
