import '../constants/app_constants.dart';
import '../theme/category_palette.dart';
import '../utils/money.dart';

/// Converte snapshots (backup local ou na nuvem) de versões anteriores do
/// schema para o formato atual, antes de gravá-los no banco.
abstract final class SnapshotMigrator {
  /// Tabelas e colunas aceitas na restauração, na ordem de inserção
  /// (tabelas referenciadas antes das que as referenciam).
  static const columns = {
    'accounts': ['id', 'name', 'initial_balance_cents', 'created_at'],
    'categories': ['id', 'name', 'type', 'icon', 'color', 'is_default'],
    'transactions': [
      'id',
      'type',
      'amount_cents',
      'category_id',
      'account_id',
      'date',
      'description',
      'is_paid',
      'installment_group',
      'installment_number',
      'installment_count',
      'created_at',
    ],
    'goals': [
      'id',
      'name',
      'target_amount_cents',
      'current_amount_cents',
      'deadline',
      'created_at',
    ],
  };

  /// Devolve as linhas de cada tabela já no schema atual, somente com as
  /// colunas conhecidas. Lança [SnapshotException] se o snapshot for inválido
  /// ou de uma versão mais nova que este aplicativo.
  static Map<String, List<Map<String, Object?>>> upgrade(
    Map<String, dynamic> snapshot,
  ) {
    final version = (snapshot['schema_version'] as num?)?.toInt() ?? 1;
    if (version > AppConstants.databaseVersion) {
      throw const SnapshotException(
        'Este backup foi criado por uma versão mais nova do Fluxo+. '
        'Atualize o aplicativo para restaurá-lo.',
      );
    }
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in columns.keys) {
      final rows = snapshot[table];
      if (rows is! List) {
        throw const SnapshotException('Backup inválido ou incompleto.');
      }
      result[table] = [
        for (final raw in rows)
          if (raw is Map) Map<String, Object?>.from(raw),
      ];
    }
    if (version < 3) _toCents(result);
    for (final entry in result.entries) {
      final allowed = columns[entry.key]!;
      result[entry.key] = [
        for (final row in entry.value)
          {
            for (final column in allowed)
              if (row.containsKey(column)) column: row[column],
          },
      ];
    }
    return result;
  }

  static void _toCents(Map<String, List<Map<String, Object?>>> tables) {
    for (final row in tables['accounts']!) {
      row['initial_balance_cents'] =
          Money.toCents((row.remove('initial_balance') as num?) ?? 0);
    }
    for (final row in tables['transactions']!) {
      row['amount_cents'] = Money.toCents((row.remove('amount') as num?) ?? 0);
    }
    for (final row in tables['goals']!) {
      row['target_amount_cents'] =
          Money.toCents((row.remove('target_amount') as num?) ?? 0);
      row['current_amount_cents'] =
          Money.toCents((row.remove('current_amount') as num?) ?? 0);
    }
    for (final row in tables['categories']!) {
      final name = row['name'];
      if (row['is_default'] == 1 &&
          CategoryPalette.legacyDefaults[name] == row['color']) {
        row['color'] = CategoryPalette.defaults[name];
      }
    }
  }
}

class SnapshotException implements Exception {
  const SnapshotException(this.message);

  final String message;

  @override
  String toString() => message;
}
