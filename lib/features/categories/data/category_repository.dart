import '../../../core/database/app_database.dart';
import '../../../shared/models/category.dart';

class CategoryRepository {
  CategoryRepository(this._database);

  final AppDatabase _database;

  Future<List<CategoryUsage>> list() async {
    final rows = await _database.db.rawQuery('''
      SELECT c.*, COUNT(t.id) AS usage_count
      FROM categories c
      LEFT JOIN transactions t ON t.category_id = c.id
      GROUP BY c.id
      ORDER BY c.type DESC, c.name
    ''');
    return rows
        .map(
          (row) => CategoryUsage(
            category: Category.fromMap(row),
            usageCount: row['usage_count'] as int,
          ),
        )
        .toList();
  }

  Future<int> save(Category category) {
    if (category.id == null) {
      return _database.db.insert('categories', category.toMap());
    }
    return _database.db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<bool> delete(int id) async {
    final rows = await _database.db.rawQuery(
      'SELECT COUNT(*) AS count FROM transactions WHERE category_id = ?',
      [id],
    );
    if ((rows.first['count'] as int) > 0) return false;
    await _database.db.delete('categories', where: 'id = ?', whereArgs: [id]);
    return true;
  }
}

class CategoryUsage {
  const CategoryUsage({required this.category, required this.usageCount});

  final Category category;
  final int usageCount;
}
