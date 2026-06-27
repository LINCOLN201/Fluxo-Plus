import '../../../core/database/app_database.dart';
import '../../../shared/models/goal.dart';

class GoalRepository {
  GoalRepository(this._database);

  final AppDatabase _database;

  Future<List<Goal>> list() async {
    final rows = await _database.db.query(
      'goals',
      orderBy: 'created_at DESC',
    );
    return rows.map(Goal.fromMap).toList();
  }

  Future<int> save(Goal goal) {
    if (goal.id == null) {
      return _database.db.insert('goals', goal.toMap());
    }
    return _database.db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> delete(int id) =>
      _database.db.delete('goals', where: 'id = ?', whereArgs: [id]);
}
