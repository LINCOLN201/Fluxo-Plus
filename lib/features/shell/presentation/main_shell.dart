import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../accounts/data/account_repository.dart';
import '../../categories/data/category_repository.dart';
import '../../goals/data/goal_repository.dart';
import '../../reports/data/report_repository.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/presentation/new_transaction_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../accounts/presentation/accounts_screen.dart';
import '../../categories/presentation/categories_screen.dart';
import '../../goals/presentation/goals_screen.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../../../core/sync/cloud_sync_service.dart';
import '../../../core/update/update_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.dashboardRepository,
    required this.transactionRepository,
    required this.themeMode,
    required this.onThemeChanged,
    required this.accountRepository,
    required this.categoryRepository,
    required this.goalRepository,
    required this.reportRepository,
    required this.cloudSyncService,
    required this.biometricEnabled,
    required this.onBiometricChanged,
    required this.updateService,
  });

  final DashboardRepository dashboardRepository;
  final TransactionRepository transactionRepository;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final AccountRepository accountRepository;
  final CategoryRepository categoryRepository;
  final GoalRepository goalRepository;
  final ReportRepository reportRepository;
  final CloudSyncService cloudSyncService;
  final bool biometricEnabled;
  final Future<bool> Function(bool) onBiometricChanged;
  final UpdateService updateService;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _dashboardRevision = 0;

  static const _items = [
    (Icons.grid_view_rounded, 'Dashboard'),
    (Icons.swap_horiz_rounded, 'Transações'),
    (Icons.account_balance_wallet_outlined, 'Contas'),
    (Icons.track_changes_rounded, 'Metas'),
    (Icons.bar_chart_rounded, 'Relatórios'),
    (Icons.category_outlined, 'Categorias'),
    (Icons.settings_outlined, 'Configurações'),
  ];

  Future<void> _addTransaction() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewTransactionScreen(
          repository: widget.transactionRepository,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        _selectedIndex = 0;
        _dashboardRevision++;
      });
    }
  }

  Widget _page() {
    return switch (_selectedIndex) {
      0 => DashboardScreen(
          key: ValueKey(_dashboardRevision),
          repository: widget.dashboardRepository,
          onAddTransaction: _addTransaction,
        ),
      1 => TransactionsScreen(
          repository: widget.transactionRepository,
          onChanged: () => setState(() => _dashboardRevision++),
        ),
      2 => AccountsScreen(repository: widget.accountRepository),
      3 => GoalsScreen(repository: widget.goalRepository),
      4 => ReportsScreen(repository: widget.reportRepository),
      5 => CategoriesScreen(repository: widget.categoryRepository),
      _ => SettingsScreen(
          themeMode: widget.themeMode,
          onThemeChanged: widget.onThemeChanged,
          cloudSyncService: widget.cloudSyncService,
          biometricEnabled: widget.biometricEnabled,
          onBiometricChanged: widget.onBiometricChanged,
          updateService: widget.updateService,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        if (!desktop) {
          return Scaffold(
            backgroundColor:
                dark ? const Color(0xFF0D1820) : const Color(0xFFF6F8FA),
            body: _page(),
            bottomNavigationBar: _MobileNavigation(
              dark: dark,
              selectedIndex: switch (_selectedIndex) {
                0 => 0,
                1 => 1,
                4 => 2,
                _ => 3,
              },
              onSelected: (value) => setState(
                () => _selectedIndex = const [0, 1, 4, 6][value],
              ),
              onAdd: _addTransaction,
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              _DesktopSidebar(
                dark: dark,
                selectedIndex: _selectedIndex,
                onSelected: (value) => setState(() => _selectedIndex = value),
              ),
              Expanded(child: _page()),
            ],
          ),
        );
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.dark,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final bool dark;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: Color(0xFF26343D))),
      ),
      color: dark ? const Color(0xFF111E27) : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Row(
                children: [
                  _FluxoMark(size: 34),
                  SizedBox(width: 12),
                  Text(
                    'Fluxo',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '+',
                    style: TextStyle(
                      fontSize: 28,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _MainShellState._items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = _MainShellState._items[index];
                  final selected = selectedIndex == index;
                  return Material(
                    color:
                        selected ? const Color(0xFFE4F7EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.$1,
                              size: 20,
                              color: selected
                                  ? AppColors.primaryDark
                                  : dark
                                      ? const Color(0xFF9AA8B1)
                                      : const Color(0xFF41505C),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              item.$2,
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: selected
                                    ? AppColors.primaryDark
                                    : dark
                                        ? const Color(0xFFE8EEF2)
                                        : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE4F7EB),
                    child: Icon(Icons.person_outline, color: AppColors.primary),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meu perfil',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Dados locais',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({
    required this.dark,
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final bool dark;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Início'),
      (Icons.swap_horiz_rounded, 'Transações'),
      (Icons.bar_chart_rounded, 'Relatórios'),
      (Icons.more_horiz_rounded, 'Mais'),
    ];
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111E27) : Colors.white,
        border: Border(
          top: BorderSide(
            color: dark ? const Color(0xFF22313B) : const Color(0xFFE2E8EE),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ...List.generate(2, (index) => _mobileItem(items[index], index)),
          Semantics(
            button: true,
            label: 'Nova transação',
            child: InkWell(
              onTap: onAdd,
              customBorder: const CircleBorder(),
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x660F9D58),
                      blurRadius: 18,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ),
          ...List.generate(
            2,
            (offset) => _mobileItem(items[offset + 2], offset + 2),
          ),
        ],
      ),
    );
  }

  Widget _mobileItem((IconData, String) item, int index) {
    final selected = selectedIndex == index;
    return InkWell(
      onTap: () => onSelected(index),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.$1,
              color: selected ? AppColors.primary : const Color(0xFF82909A),
            ),
            const SizedBox(height: 4),
            Text(
              item.$2,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.primary : const Color(0xFF82909A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FluxoMark extends StatelessWidget {
  const _FluxoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.5, -0.65),
            child: Container(
              width: size * .78,
              height: size * .28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.65, 0.4),
            child: Transform.rotate(
              angle: -.35,
              child: Container(
                width: size * .32,
                height: size * .7,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
