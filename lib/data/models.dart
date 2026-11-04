// Data models. Column names match the existing SQLite schema exactly
// (see [TodoDatabase]), so data written by earlier builds keeps working.

class TodoCategory {
  final int id;
  final String name;

  const TodoCategory({required this.id, required this.name});

  factory TodoCategory.fromMap(Map<String, dynamic> map) =>
      TodoCategory(id: map['id'] as int, name: map['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  /// The seeded "All" pseudo-category (first default row).
  bool get isAll => name == 'All';
}

class TodoItem {
  final int id;
  final String title;
  final String? description;
  final bool isDone;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? reminderAt;
  final DateTime? closedAt;
  final int sortOrder;

  const TodoItem({
    required this.id,
    required this.title,
    this.description,
    required this.isDone,
    this.categoryId,
    required this.createdAt,
    this.reminderAt,
    this.closedAt,
    this.sortOrder = 0,
  });

  factory TodoItem.fromMap(Map<String, dynamic> map) => TodoItem(
        id: map['id'] as int,
        title: map['title'] as String,
        description: map['description'] as String?,
        isDone: (map['isDone'] as int) == 1,
        categoryId: map['categoryId'] as int?,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        reminderAt: map['reminderAt'] == null
            ? null
            : DateTime.tryParse(map['reminderAt'] as String),
        closedAt: map['closedAt'] == null
            ? null
            : DateTime.tryParse(map['closedAt'] as String),
        sortOrder: (map['sortOrder'] as int?) ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'isDone': isDone ? 1 : 0,
        'categoryId': categoryId,
        'createdAt': createdAt.toIso8601String(),
        'reminderAt': reminderAt?.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'sortOrder': sortOrder,
      };

  TodoItem copyWith({
    String? title,
    String? description,
    bool? isDone,
    int? categoryId,
    DateTime? reminderAt,
    bool clearReminder = false,
    DateTime? closedAt,
    bool clearClosedAt = false,
    int? sortOrder,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
