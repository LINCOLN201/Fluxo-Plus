import '../../../core/database/app_database.dart';
import '../../../core/utils/installment_schedule.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/account.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/finance_transaction.dart';

class TransactionRepository {
  TransactionRepository(this._database);

  final AppDatabase _database;

  Future<List<Account>> getAccounts() async {
    final rows = await _database.db.query('accounts', orderBy: 'name');
    return rows.map(Account.fromMap).toList();
  }

  Future<List<Category>> getCategories(TransactionType type) async {
    final rows = await _database.db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'name',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<TransactionRecord>> list({
    DateTime? month,
    TransactionType? type,
    int? categoryId,
    PaymentFilter payment = PaymentFilter.all,
  }) async {
    final conditions = <String>[];
    final arguments = <Object?>[];
    if (month != null) {
      conditions.add('t.date >= ? AND t.date < ?');
      arguments
        ..add(DateTime(month.year, month.month).toIso8601String())
        ..add(DateTime(month.year, month.month + 1).toIso8601String());
    }
    if (type != null) {
      conditions.add('t.type = ?');
      arguments.add(type.name);
    }
    if (categoryId != null) {
      conditions.add('t.category_id = ?');
      arguments.add(categoryId);
    } else {
      // Assinaturas já têm tela própria; sem isso, apareciam duplicadas
      // aqui e lá, sem nenhuma informação a mais na lista geral.
      conditions.add("c.name != 'Assinaturas'");
    }
    if (payment == PaymentFilter.pending) {
      conditions.add('t.is_paid = 0');
    } else if (payment == PaymentFilter.paid) {
      conditions.add('t.is_paid = 1');
    }
    final rows = await _database.db.rawQuery(
      '''
      SELECT t.*, c.name AS category_name, c.color AS category_color,
             c.icon AS category_icon,
             a.name AS account_name
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      INNER JOIN accounts a ON a.id = t.account_id
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY
        CASE WHEN t.is_paid = 0 THEN 0 ELSE 1 END,
        CASE WHEN t.is_paid = 0 THEN t.date END ASC,
        CASE WHEN t.is_paid = 1 THEN t.date END DESC,
        t.id DESC
      ''',
      arguments,
    );
    return rows.map(TransactionRecord.fromMap).toList();
  }

  Future<FinanceTransaction?> find(int id) async {
    final rows = await _database.db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : FinanceTransaction.fromMap(rows.first);
  }

  Future<List<Category>> getAllCategories() async {
    final rows = await _database.db.query('categories', orderBy: 'name');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> create(FinanceTransaction transaction) =>
      _database.db.insert('transactions', transaction.toMap());

  Future<List<int>> createInstallments(
    FinanceTransaction transaction,
    int count,
  ) async {
    if (count < 1 || count > 120) {
      throw ArgumentError.value(count, 'count', 'Use entre 1 e 120 parcelas.');
    }
    final group =
        count == 1 ? null : 'parcelas-${DateTime.now().microsecondsSinceEpoch}';
    final dates = InstallmentSchedule.dueDates(transaction.date, count);
    return _database.db.transaction((txn) async {
      final ids = <int>[];
      for (var index = 0; index < count; index++) {
        ids.add(
          await txn.insert(
            'transactions',
            FinanceTransaction(
              type: transaction.type,
              amount: transaction.amount,
              categoryId: transaction.categoryId,
              accountId: transaction.accountId,
              date: dates[index],
              description: transaction.description,
              createdAt: transaction.createdAt,
              isPaid: index == 0 ? transaction.isPaid : false,
              installmentGroup: group,
              installmentNumber: index + 1,
              installmentCount: count,
            ).toMap(),
          ),
        );
      }
      return ids;
    });
  }

  /// Gera as próximas [monthsAhead] ocorrências mensais (a primeira na data
  /// de [transaction], as seguintes um mês depois cada uma), vinculadas por
  /// um `recurring_group` compartilhado. Ao contrário de [createInstallments]
  /// (quantidade fixa e conhecida, ex.: 12x de um parcelamento), uma
  /// recorrência não tem fim — o grupo é completado aos poucos por
  /// [extendRecurringOccurrences] conforme o tempo passa, em vez de gerar
  /// anos de lançamentos de uma vez.
  Future<List<int>> createRecurring(
    FinanceTransaction transaction, {
    int monthsAhead = 12,
  }) async {
    final group = 'recorrente-${DateTime.now().microsecondsSinceEpoch}';
    final dates = InstallmentSchedule.dueDates(transaction.date, monthsAhead);
    return _database.db.transaction((txn) async {
      final ids = <int>[];
      for (var index = 0; index < dates.length; index++) {
        ids.add(
          await txn.insert(
            'transactions',
            FinanceTransaction(
              type: transaction.type,
              amount: transaction.amount,
              categoryId: transaction.categoryId,
              accountId: transaction.accountId,
              date: dates[index],
              description: transaction.description,
              createdAt: transaction.createdAt,
              isPaid: index == 0 ? transaction.isPaid : false,
              recurringGroup: group,
            ).toMap(),
          ),
        );
      }
      return ids;
    });
  }

  /// Completa cada recorrência existente até ter pelo menos [monthsAhead]
  /// meses de lançamentos à frente de hoje, gerando mais ocorrências só
  /// quando o horizonte já gerado está a menos de [refillThreshold] meses
  /// do fim. Chamado uma vez ao abrir o app (ver `main_shell.dart`) — sem
  /// isso, uma recorrência criada há muito tempo ficaria sem novos
  /// lançamentos assim que as ocorrências geradas inicialmente acabassem.
  Future<void> extendRecurringOccurrences({
    int monthsAhead = 12,
    int refillThreshold = 3,
  }) async {
    // As colunas fora do MAX() aqui vêm da MESMA linha que tem a maior
    // data — comportamento específico do SQLite (garantido quando a
    // consulta tem um único MAX()/MIN()), não um SELECT ambíguo: assim a
    // nova ocorrência copia valor/categoria/conta da última gerada, não de
    // uma linha qualquer do grupo.
    final groupRows = await _database.db.rawQuery('''
      SELECT recurring_group, MAX(date) AS last_date, type, amount_cents,
             category_id, account_id, description
      FROM transactions
      WHERE recurring_group IS NOT NULL
      GROUP BY recurring_group
    ''');
    final now = DateTime.now();
    final refillBefore = DateTime(now.year, now.month + refillThreshold);
    for (final row in groupRows) {
      final lastDate = DateTime.parse(row['last_date'] as String);
      if (!lastDate.isBefore(refillBefore)) continue;
      final template = FinanceTransaction(
        type: TransactionType.values.byName(row['type'] as String),
        amount: Money.fromCents(row['amount_cents']),
        categoryId: row['category_id'] as int,
        accountId: row['account_id'] as int,
        date: lastDate,
        description: row['description'] as String,
        createdAt: now,
      );
      final targetLastDate = DateTime(now.year, now.month + monthsAhead);
      final monthsToAdd = (targetLastDate.year - lastDate.year) * 12 +
          (targetLastDate.month - lastDate.month);
      if (monthsToAdd <= 0) continue;
      // dueDates(lastDate, monthsToAdd + 1) inclui lastDate no índice 0
      // (já existe no banco); skip(1) fica só com as datas novas.
      final dates =
          InstallmentSchedule.dueDates(lastDate, monthsToAdd + 1).skip(1);
      await _database.db.transaction((txn) async {
        for (final date in dates) {
          await txn.insert(
            'transactions',
            FinanceTransaction(
              type: template.type,
              amount: template.amount,
              categoryId: template.categoryId,
              accountId: template.accountId,
              date: date,
              description: template.description,
              createdAt: now,
              isPaid: false,
              recurringGroup: row['recurring_group'] as String,
            ).toMap(),
          );
        }
      });
    }
  }

  /// Cancela uma recorrência: apaga só as ocorrências futuras e ainda
  /// pendentes daquele grupo — o histórico (passadas ou já pagas) fica
  /// intacto.
  Future<void> stopRecurring(String group) async {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    await _database.db.delete(
      'transactions',
      where: 'recurring_group = ? AND is_paid = 0 AND date >= ?',
      whereArgs: [group, today.toIso8601String()],
    );
  }

  Future<void> update(FinanceTransaction transaction) async {
    if (transaction.id == null) {
      throw ArgumentError('A transação precisa ter um id para ser editada.');
    }
    await _database.db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> delete(int id) async {
    await _database.db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setPaid(int id, bool paid) async {
    await _database.db.update(
      'transactions',
      {'is_paid': paid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<TransactionRecord>> dueAlerts({
    int daysAhead = 7,
  }) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(Duration(days: daysAhead + 1));
    final rows = await _database.db.rawQuery(
      '''
      SELECT t.*, c.name AS category_name, c.color AS category_color,
             c.icon AS category_icon, a.name AS account_name
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      INNER JOIN accounts a ON a.id = t.account_id
      WHERE t.type = 'expense' AND t.is_paid = 0 AND t.date < ?
      ORDER BY t.date ASC, t.id ASC
      ''',
      [end.toIso8601String()],
    );
    return rows.map(TransactionRecord.fromMap).toList();
  }

  /// Assinaturas ativas (streamers, música, nuvem etc.): lançamentos
  /// recorrentes da categoria "Assinaturas". Mesma lógica de
  /// [extendRecurringOccurrences] — como há um único MIN() na consulta, as
  /// colunas soltas vêm da mesma linha da próxima cobrança pendente daquele
  /// grupo, então descrição e valor batem com a próxima ocorrência, não com
  /// uma linha qualquer do grupo.
  Future<List<SubscriptionSummary>> listActiveSubscriptions() async {
    final rows = await _database.db.rawQuery('''
      SELECT t.recurring_group AS recurring_group, t.description,
             t.amount_cents, MIN(t.date) AS next_date
      FROM transactions t
      INNER JOIN categories c ON c.id = t.category_id
      WHERE c.name = 'Assinaturas' AND t.recurring_group IS NOT NULL
        AND t.is_paid = 0
      GROUP BY t.recurring_group
      ORDER BY next_date ASC
    ''');
    return rows.map(SubscriptionSummary.fromMap).toList();
  }
}

class SubscriptionSummary {
  const SubscriptionSummary({
    required this.recurringGroup,
    required this.description,
    required this.amount,
    required this.nextDate,
  });

  final String recurringGroup;
  final String description;
  final double amount;
  final DateTime nextDate;

  factory SubscriptionSummary.fromMap(Map<String, Object?> map) =>
      SubscriptionSummary(
        recurringGroup: map['recurring_group'] as String,
        description: map['description'] as String,
        amount: Money.fromCents(map['amount_cents']),
        nextDate: DateTime.parse(map['next_date'] as String),
      );
}

class TransactionRecord {
  const TransactionRecord({
    required this.transaction,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    required this.accountName,
  });

  final FinanceTransaction transaction;
  final String categoryName;
  final int categoryColor;
  final String categoryIcon;
  final String accountName;

  factory TransactionRecord.fromMap(Map<String, Object?> map) =>
      TransactionRecord(
        transaction: FinanceTransaction.fromMap(map),
        categoryName: map['category_name'] as String,
        categoryColor: map['category_color'] as int,
        categoryIcon: map['category_icon'] as String,
        accountName: map['account_name'] as String,
      );
}

enum PaymentFilter { all, pending, paid }
