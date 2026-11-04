import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite storage.
///
/// Uses the same database file (`todo.db`) and the same schema as the
/// original app, so an upgrade keeps existing categories and todos.
class TodoDatabase {
  TodoDatabase._();
  static final TodoDatabase instance = TodoDatabase._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'todo.db'),
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            isDone INTEGER NOT NULL,
            categoryId INTEGER,
            createdAt TEXT NOT NULL,
            reminderAt TEXT,
            closedAt TEXT,
            sortOrder INTEGER DEFAULT 0,
            FOREIGN KEY (categoryId) REFERENCES categories(id)
          )
        ''');
        await _seed(db);
      },
    );
  }

  Future<void> _seed(Database db) async {
    final batch = db.batch();
    for (final name in ['All', 'Work', 'Personal', 'Shopping']) {
      batch.insert('categories', {'name': name});
    }
    batch.insert('todos', {
      'title': 'Welcome to Todo App 🎯',
      'description': 'Tap the checkbox to complete a task, swipe to delete.',
      'isDone': 0,
      'categoryId': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'closedAt': null,
      'sortOrder': 0,
    });
    await batch.commit(noResult: true);
  }

  // --- Categories -----------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'id ASC');
  }

  Future<int> insertCategory(String name) async {
    final db = await database;
    return db.insert('categories', {'name': name});
  }

  Future<void> updateCategory(int id, String name) async {
    final db = await database;
    await db.update('categories', {'name': name},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.update('todos', {'categoryId': null},
        where: 'categoryId = ?', whereArgs: [id]);
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- Todos ----------------------------------------------------------------

  Future<List<Map<String, dynamic>>> fetchTodos() async {
    final db = await database;
    return db.query('todos', orderBy: 'sortOrder ASC, createdAt DESC');
  }

  Future<int> insertTodo(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('todos', row);
  }

  Future<void> updateTodo(int id, Map<String, dynamic> row) async {
    final db = await database;
    await db.update('todos', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTodo(int id) async {
    final db = await database;
    await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSortOrders(List<int> orderedIds) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update('todos', {'sortOrder': i},
          where: 'id = ?', whereArgs: [orderedIds[i]]);
    }
    await batch.commit(noResult: true);
  }
}
