import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers.dart';
import 'task_card.dart';
import 'task_form_sheet.dart';

class KanbanColumn extends ConsumerWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.tasks,
    required this.categories,
  });

  final String status;
  final List<Task> tasks;
  final List<Category> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = AppTheme.statusStyle(status);
    final db = ref.read(databaseProvider);

    return DragTarget<Task>(
      onAcceptWithDetails: (details) {
        final task = details.data;
        if (task.status != status) {
          db.updateTaskStatus(task.id, status);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 300,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isHovering ? style.bg : AppTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHovering ? style.color.withAlpha(120) : AppTheme.border,
              width: isHovering ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Column header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: style.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      style.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: style.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: style.color,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openCreateSheet(context, status),
                      child: Icon(Icons.add,
                          size: 18, color: style.color),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: AppTheme.border),

              // Task list
              Expanded(
                child: tasks.isEmpty
                    ? _EmptyColumn(
                        status: status,
                        color: style.color,
                        onAdd: () => _openCreateSheet(context, status),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final category = categories
                              .where((c) => c.id == task.categoryId)
                              .firstOrNull;

                          return LongPressDraggable<Task>(
                            data: task,
                            delay: const Duration(milliseconds: 200),
                            feedback: Material(
                              color: Colors.transparent,
                              child: Opacity(
                                opacity: 0.85,
                                child: SizedBox(
                                  width: 270,
                                  child: TaskCard(
                                    task: task,
                                    category: category,
                                    onTap: () {},
                                    onDelete: () {},
                                  ),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCard(
                                task: task,
                                category: category,
                                onTap: () {},
                                onDelete: () {},
                              ),
                            ),
                            child: TaskCard(
                              task: task,
                              category: category,
                              onTap: () => _openEditSheet(context, task),
                              onDelete: () => db.deleteTask(task.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateSheet(BuildContext context, String initialStatus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(initialStatus: initialStatus),
    );
  }

  void _openEditSheet(BuildContext context, Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskFormSheet(task: task),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  const _EmptyColumn({required this.status, required this.color, required this.onAdd});
  final String status;
  final Color color;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: color.withAlpha(140)),
          const SizedBox(height: 10),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 13,
              color: color.withAlpha(180),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Add task',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
