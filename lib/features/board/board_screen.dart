import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import 'widgets/kanban_column.dart';
import 'widgets/task_form_sheet.dart';

class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoTasks = ref.watch(todoTasksProvider).valueOrNull ?? [];
    final doingTasks = ref.watch(doingTasksProvider).valueOrNull ?? [];
    final doneTasks = ref.watch(doneTasksProvider).valueOrNull ?? [];
    final categories = ref.watch(allCategoriesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Board'),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KanbanColumn(
              status: 'todo',
              tasks: todoTasks,
              categories: categories,
            ),
            KanbanColumn(
              status: 'doing',
              tasks: doingTasks,
              categories: categories,
            ),
            KanbanColumn(
              status: 'done',
              tasks: doneTasks,
              categories: categories,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TaskFormSheet(),
    );
  }
}
