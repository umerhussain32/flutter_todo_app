import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/todo_store.dart';
import '../utils/format.dart';
import 'todo_editor_screen.dart';

/// Task list with category filter chips. Supports add (FAB on the
/// dashboard), tap-to-edit, swipe-to-delete, checkbox completion and
/// drag-to-reorder.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = TodoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Tasks',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.folder_outlined),
                tooltip: 'Manage categories',
                onPressed: () => _showCategoryManager(context),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryBar(store: store),
              Expanded(child: _TodoList(store: store)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategoryManager(BuildContext context) async {
    final store = TodoStore.instance;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final editable =
                store.categories.where((c) => !c.isAll).toList();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categories',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (editable.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('No custom categories yet.'),
                      ),
                    for (final c in editable)
                      ListTile(
                        dense: true,
                        title: Text(c.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _renameCategory(context, c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await store.deleteCategory(c);
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add category'),
                        onPressed: () => _addCategory(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addCategory(BuildContext context) async {
    final name = await _categoryNameDialog(context, title: 'New category');
    if (name != null && name.trim().isNotEmpty) {
      await TodoStore.instance.addCategory(name.trim());
    }
  }

  Future<void> _renameCategory(BuildContext context, TodoCategory c) async {
    final name = await _categoryNameDialog(context,
        title: 'Rename category', initial: c.name);
    if (name != null && name.trim().isNotEmpty) {
      await TodoStore.instance.renameCategory(c, name.trim());
    }
  }

  Future<String?> _categoryNameDialog(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final TodoStore store;
  const _CategoryBar({required this.store});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final c in store.categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(c.name),
                selected: c.isAll
                    ? store.selectedCategoryId == null
                    : store.selectedCategoryId == c.id,
                onSelected: (_) =>
                    store.selectCategory(c.isAll ? null : c.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  final TodoStore store;
  const _TodoList({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(store.loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: store.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final todos = store.visibleTodos;
    if (todos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/empty_task.webp', height: 160),
              const SizedBox(height: 16),
              const Text(
                'Nothing here yet.\nTap + to add your first task.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
      itemCount: todos.length,
      onReorderItem: store.reorder,
      itemBuilder: (context, i) {
        final todo = todos[i];
        return _TodoCard(key: ValueKey(todo.id), todo: todo, store: store);
      },
    );
  }
}

class _TodoCard extends StatelessWidget {
  final TodoItem todo;
  final TodoStore store;
  const _TodoCard({super.key, required this.todo, required this.store});

  @override
  Widget build(BuildContext context) {
    final category = store.categoryById(todo.categoryId);
    return Dismissible(
      key: ValueKey('dismiss-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await store.deleteTodo(todo);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task deleted')),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TodoEditorScreen(existing: todo),
              ),
            );
          },
          leading: Checkbox(
            value: todo.isDone,
            onChanged: (_) => store.toggleDone(todo),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isDone ? TextDecoration.lineThrough : null,
              color: todo.isDone ? Colors.grey : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (todo.description != null && todo.description!.isNotEmpty)
                Text(
                  todo.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (category != null && !category.isAll) ...[
                    Icon(Icons.folder_outlined,
                        size: 13, color: Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Text(category.name,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.event_outlined,
                      size: 13, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(formatDate(todo.createdAt),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  if (todo.reminderAt != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.alarm,
                        size: 13,
                        color: todo.reminderAt!.isBefore(DateTime.now()) &&
                                !todo.isDone
                            ? Colors.red
                            : Colors.grey.shade600),
                    const SizedBox(width: 3),
                    Text(formatDateTime(todo.reminderAt!),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.drag_handle, color: Colors.grey),
        ),
      ),
    );
  }
}
