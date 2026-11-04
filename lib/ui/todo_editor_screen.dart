import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/todo_store.dart';
import '../utils/format.dart';

/// Add / edit a todo: title, notes, category and an optional reminder.
class TodoEditorScreen extends StatefulWidget {
  final TodoItem? existing;
  const TodoEditorScreen({super.key, this.existing});

  @override
  State<TodoEditorScreen> createState() => _TodoEditorScreenState();
}

class _TodoEditorScreenState extends State<TodoEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  int? _categoryId;
  DateTime? _reminderAt;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _categoryId = e?.categoryId ?? TodoStore.instance.selectedCategoryId;
    _reminderAt = e?.reminderAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final initial = _reminderAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    setState(() {
      _reminderAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the task a title first')),
      );
      return;
    }
    setState(() => _saving = true);
    final store = TodoStore.instance;
    final description =
        _description.text.trim().isEmpty ? null : _description.text.trim();
    try {
      if (_isEditing) {
        await store.editTodo(
          widget.existing!,
          title: title,
          description: description,
          categoryId: _categoryId,
          reminderAt: _reminderAt,
          clearReminder: _reminderAt == null,
        );
      } else {
        await store.addTodo(
          title: title,
          description: description,
          categoryId: _categoryId,
          reminderAt: _reminderAt,
        );
      }
    } catch (_) {
      // The store reloads from the database either way; never trap the
      // user on this screen because of a save hiccup.
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await TodoStore.instance.deleteTodo(widget.existing!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = TodoStore.instance;
    final selectableCategories =
        store.categories.where((c) => !c.isAll).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit task' : 'New task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete task',
              onPressed: _delete,
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                controller: _title,
                autofocus: !_isEditing,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'What needs doing?',
                  border: InputBorder.none,
                ),
              ),
              const Divider(),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Notes (optional)',
                  border: InputBorder.none,
                  icon: Icon(Icons.notes_outlined),
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.folder_outlined),
                title: const Text('TodoCategory'),
                trailing: DropdownButton<int?>(
                  value: _categoryId != null &&
                          selectableCategories
                              .any((c) => c.id == _categoryId)
                      ? _categoryId
                      : null,
                  hint: const Text('None'),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None'),
                    ),
                    for (final c in selectableCategories)
                      DropdownMenuItem<int?>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.alarm),
                title: const Text('Reminder'),
                subtitle: Text(
                  _reminderAt == null
                      ? 'No reminder'
                      : formatDateTime(_reminderAt!),
                ),
                trailing: _reminderAt == null
                    ? TextButton(
                        onPressed: _pickReminder,
                        child: const Text('Set'),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _reminderAt = null),
                      ),
                onTap: _pickReminder,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving
                    ? 'Saving…'
                    : (_isEditing ? 'Save changes' : 'Add task')),
              ),
            ],
          );
        },
      ),
    );
  }
}
