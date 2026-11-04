import 'package:flutter/foundation.dart';

import '../services/notification_service.dart';
import 'models.dart';
import 'todo_database.dart';

/// Single source of truth for the UI.
///
/// Loading is defensive: if the database cannot be opened for any reason,
/// the store still reports itself as loaded (with empty lists) so the app
/// always reaches a usable screen instead of hanging on a splash.
class TodoStore extends ChangeNotifier {
  TodoStore._();
  static final TodoStore instance = TodoStore._();

  final TodoDatabase _db = TodoDatabase.instance;

  bool _loading = true;
  bool get loading => _loading;

  String? _loadError;
  String? get loadError => _loadError;

  List<TodoCategory> _categories = [];
  List<TodoCategory> get categories => _categories;

  List<TodoItem> _todos = [];
  List<TodoItem> get todos => _todos;

  /// Selected category filter; null means the seeded "All" category.
  int? selectedCategoryId;

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await load();
    // Notifications are optional garnish — initialise off the startup path.
    NotificationService.instance.init();
  }

  Future<void> load() async {
    try {
      final catRows = await _db.fetchCategories();
      _categories = catRows.map(TodoCategory.fromMap).toList();
      final todoRows = await _db.fetchTodos();
      _todos = todoRows.map(TodoItem.fromMap).toList();
      _loadError = null;
    } catch (e) {
      debugPrint('TodoStore load failed: $e');
      _loadError = 'Could not open your saved data.';
      _categories = [];
      _todos = [];
    }
    _loading = false;
    notifyListeners();
  }

  TodoCategory? categoryById(int? id) {
    if (id == null) return null;
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<TodoItem> get visibleTodos {
    if (selectedCategoryId == null) return _todos;
    return _todos.where((t) => t.categoryId == selectedCategoryId).toList();
  }

  void selectCategory(int? id) {
    selectedCategoryId = id;
    notifyListeners();
  }

  // --- Todos ----------------------------------------------------------------

  Future<void> addTodo({
    required String title,
    String? description,
    int? categoryId,
    DateTime? reminderAt,
  }) async {
    final item = TodoItem(
      id: 0,
      title: title,
      description: description,
      isDone: false,
      categoryId: categoryId,
      createdAt: DateTime.now(),
      reminderAt: reminderAt,
      sortOrder: _todos.isEmpty
          ? 0
          : _todos.map((t) => t.sortOrder).reduce((a, b) => a < b ? a : b) - 1,
    );
    final id = await _db.insertTodo(item.toMap());
    if (reminderAt != null) {
      NotificationService.instance
          .schedule(id: id, title: title, when: reminderAt);
    }
    await load();
  }

  Future<void> editTodo(
    TodoItem item, {
    required String title,
    String? description,
    int? categoryId,
    DateTime? reminderAt,
    bool clearReminder = false,
  }) async {
    final updated = item.copyWith(
      title: title,
      description: description,
      categoryId: categoryId,
      reminderAt: reminderAt,
      clearReminder: clearReminder,
    );
    await _db.updateTodo(item.id, updated.toMap());
    await NotificationService.instance.cancel(item.id);
    final effectiveReminder = clearReminder ? null : updated.reminderAt;
    if (effectiveReminder != null) {
      NotificationService.instance.schedule(
          id: item.id, title: title, when: effectiveReminder);
    }
    await load();
  }

  Future<void> toggleDone(TodoItem item) async {
    final updated = item.copyWith(
      isDone: !item.isDone,
      closedAt: !item.isDone ? DateTime.now() : null,
      clearClosedAt: !item.isDone == false,
    );
    await _db.updateTodo(item.id, updated.toMap());
    if (updated.isDone) {
      await NotificationService.instance.cancel(item.id);
    }
    await load();
  }

  Future<void> deleteTodo(TodoItem item) async {
    await NotificationService.instance.cancel(item.id);
    await _db.deleteTodo(item.id);
    await load();
  }

  /// [newIndex] follows ReorderableListView.onReorderItem semantics:
  /// it is already adjusted for the removed item.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final visible = visibleTodos;
    if (oldIndex < 0 || oldIndex >= visible.length) return;
    final moved = visible.removeAt(oldIndex);
    newIndex = newIndex.clamp(0, visible.length);
    visible.insert(newIndex, moved);
    // Persist the new order for the visible subset.
    final order = _todos.map((t) => t.id).toList();
    final visibleIds = visible.map((t) => t.id).toList();
    var vi = 0;
    for (var i = 0; i < order.length && vi < visibleIds.length; i++) {
      if (visibleIds.contains(order[i])) {
        order[i] = visibleIds[vi++];
      }
    }
    await _db.updateSortOrders(order);
    await load();
  }

  // --- Categories -----------------------------------------------------------

  Future<void> addCategory(String name) async {
    await _db.insertCategory(name);
    await load();
  }

  Future<void> renameCategory(TodoCategory category, String name) async {
    await _db.updateCategory(category.id, name);
    await load();
  }

  Future<void> deleteCategory(TodoCategory category) async {
    await _db.deleteCategory(category.id);
    if (selectedCategoryId == category.id) selectedCategoryId = null;
    await load();
  }

  // --- Stats ----------------------------------------------------------------

  int get totalCount => _todos.length;
  int get doneCount => _todos.where((t) => t.isDone).length;
  int get pendingCount => totalCount - doneCount;

  Map<int?, int> get doneByCategory {
    final map = <int?, int>{};
    for (final t in _todos.where((t) => t.isDone)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + 1;
    }
    return map;
  }

  Map<int?, int> get totalByCategory {
    final map = <int?, int>{};
    for (final t in _todos) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + 1;
    }
    return map;
  }
}
