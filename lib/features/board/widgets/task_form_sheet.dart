import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers.dart';

class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({super.key, this.task, this.initialStatus = 'todo'});
  final Task? task;
  final String initialStatus;

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _status = 'todo';
  int? _selectedCategoryId;
  DateTime? _dueDate;
  bool _saving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descController.text = widget.task!.description ?? '';
      _status = widget.task!.status;
      _selectedCategoryId = widget.task!.categoryId;
      _dueDate = widget.task!.dueDate;
    } else {
      _status = widget.initialStatus;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    try {
      if (_isEditing) {
        await db.updateTask(
          id: widget.task!.id,
          title: title,
          description:
              _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          status: _status,
          categoryId: _selectedCategoryId,
          dueDate: _dueDate,
        );
      } else {
        await db.createTask(
          TasksCompanion(
            title: Value(title),
            description: Value(_descController.text.trim().isEmpty
                ? null
                : _descController.text.trim()),
            status: Value(_status),
            categoryId: Value(_selectedCategoryId),
            dueDate: Value(_dueDate),
            createdAt: Value(DateTime.now()),
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _isEditing ? 'Edit task' : 'New task',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary),
            decoration: const InputDecoration(hintText: 'Task title'),
          ),
          const SizedBox(height: 10),

          // Description field
          TextField(
            controller: _descController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textPrimary),
            decoration: const InputDecoration(
                hintText: 'Description (optional)'),
          ),
          const SizedBox(height: 16),

          // Status
          _SectionLabel(label: 'Status'),
          const SizedBox(height: 8),
          _StatusRow(
            current: _status,
            onChange: (s) => setState(() => _status = s),
          ),
          const SizedBox(height: 16),

          // Category
          _SectionLabel(label: 'Category'),
          const SizedBox(height: 8),
          _CategoryRow(
            categories: categories,
            selectedId: _selectedCategoryId,
            onSelect: (id) => setState(() => _selectedCategoryId = id),
            onCreateNew: () => _showCreateCategory(context),
          ),
          const SizedBox(height: 16),

          // Due date
          _SectionLabel(label: 'Due date'),
          const SizedBox(height: 8),
          _DateButton(
            date: _dueDate,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
            onClear: () => setState(() => _dueDate = null),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Create task'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateCategorySheet(
        onCreated: (id) => setState(() => _selectedCategoryId = id),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.current, required this.onChange});
  final String current;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    const statuses = ['todo', 'doing', 'done'];
    return Row(
      children: statuses.map((s) {
        final style = AppTheme.statusStyle(s);
        final selected = current == s;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(s),
            child: Container(
              margin: EdgeInsets.only(right: s != 'done' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? style.color : AppTheme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? style.color : AppTheme.border,
                ),
              ),
              child: Text(
                style.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onCreateNew,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelect;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categories.map((cat) {
          final color = Color(cat.colorValue);
          final selected = selectedId == cat.id;
          return GestureDetector(
            onTap: () => onSelect(selected ? null : cat.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color : color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : color.withAlpha(80),
                ),
              ),
              child: Text(
                cat.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          );
        }),
        GestureDetector(
          onTap: onCreateNew,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: AppTheme.textSecondary),
                SizedBox(width: 4),
                Text(
                  'New',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton(
      {required this.date, required this.onTap, required this.onClear});
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('EEEE, MMMM d, yyyy').format(date!)
                    : 'No due date',
                style: TextStyle(
                  fontSize: 14,
                  color: date != null
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Create Category Sheet ─────────────────────────────────────────────

class _CreateCategorySheet extends ConsumerStatefulWidget {
  const _CreateCategorySheet({required this.onCreated});
  final ValueChanged<int> onCreated;

  @override
  ConsumerState<_CreateCategorySheet> createState() =>
      _CreateCategorySheetState();
}

class _CreateCategorySheetState extends ConsumerState<_CreateCategorySheet> {
  final _nameController = TextEditingController();
  int _selectedColor = AppTheme.categoryPalette.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final db = ref.read(databaseProvider);
    final id = await db.createCategory(name, _selectedColor);
    if (mounted) {
      widget.onCreated(id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'New category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Category name'),
          ),
          const SizedBox(height: 16),
          const Text(
            'COLOR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: AppTheme.categoryPalette.map((colorValue) {
              final selected = _selectedColor == colorValue;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorValue),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: AppTheme.textPrimary,
                            width: 2.5,
                          )
                        : null,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: Color(colorValue).withAlpha(100),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _create,
              child: const Text('Create category'),
            ),
          ),
        ],
      ),
    );
  }
}
