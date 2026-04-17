// ignore_for_file: avoid_dynamic_calls
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aline_native/data/database/app_database.dart';
import 'package:aline_native/data/providers.dart';
import 'package:aline_native/features/board/widgets/kanban_column.dart';
import 'package:aline_native/features/board/widgets/task_card.dart';
import 'package:aline_native/features/board/widgets/task_form_sheet.dart';

// ── Helpers ──────────────────────────────────────────────────────────

Task _makeTask({
  int id = 1,
  String title = 'Task',
  String status = 'todo',
  String? description,
}) =>
    Task(
      id: id,
      title: title,
      status: status,
      description: description,
      categoryId: null,
      dueDate: null,
      createdAt: DateTime(2025, 1, 1),
      position: 0,
    );

/// Wraps KanbanColumn with only the databaseProvider override.
/// KanbanColumn receives tasks/categories as plain params, so no
/// stream providers are needed — avoids FakeAsync drift issues.
Widget _wrapColumn({
  required AppDatabase db,
  required String status,
  List<Task> tasks = const [],
  List<Category> categories = const [],
}) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 320,
              child: KanbanColumn(
                status: status,
                tasks: tasks,
                categories: categories,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wraps TaskFormSheet with minimal overrides.
/// The allCategoriesProvider is a one-shot stream that never interacts
/// with drift, so the FakeAsync cleanup timer issue doesn't apply.
Widget _wrapForm({required AppDatabase db, Task? task}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      allCategoriesProvider
          .overrideWith((_) => Stream<List<Category>>.value([])),
    ],
    child: MaterialApp(
      home: Scaffold(body: TaskFormSheet(task: task)),
    ),
  );
}

/// Pumps a fixed number of frames — avoids pumpAndSettle hanging on
/// streams that never close.
Future<void> _settle(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Reads from the database outside FakeAsync to avoid deadlocks.
Future<List<Task>> _dbTasks(WidgetTester tester, AppDatabase db,
    String status) async {
  final result =
      await tester.runAsync(() => db.watchTasksByStatus(status).first);
  return result!;
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  // ── KanbanColumn structural ────────────────────────────────────────

  group('KanbanColumn – structure', () {
    testWidgets('todo column shows correct header', (tester) async {
      await tester.pumpWidget(_wrapColumn(db: db, status: 'todo'));
      await _settle(tester);
      expect(find.text('To Do'), findsOneWidget);
    });

    testWidgets('doing column shows correct header', (tester) async {
      await tester.pumpWidget(_wrapColumn(db: db, status: 'doing'));
      await _settle(tester);
      expect(find.text('Doing'), findsOneWidget);
    });

    testWidgets('done column shows correct header', (tester) async {
      await tester.pumpWidget(_wrapColumn(db: db, status: 'done'));
      await _settle(tester);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('empty column shows "No tasks here"', (tester) async {
      await tester.pumpWidget(_wrapColumn(db: db, status: 'todo'));
      await _settle(tester);
      expect(find.text('No tasks here'), findsOneWidget);
    });

    testWidgets('renders a TaskCard for each task', (tester) async {
      await tester.pumpWidget(_wrapColumn(
        db: db,
        status: 'todo',
        tasks: [
          _makeTask(id: 1, title: 'Alpha'),
          _makeTask(id: 2, title: 'Beta'),
        ],
      ));
      await _settle(tester);
      expect(find.byType(TaskCard), findsNWidgets(2));
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('count badge equals number of tasks', (tester) async {
      await tester.pumpWidget(_wrapColumn(
        db: db,
        status: 'todo',
        tasks: [
          _makeTask(id: 1, title: 'A'),
          _makeTask(id: 2, title: 'B'),
          _makeTask(id: 3, title: 'C'),
        ],
      ));
      await _settle(tester);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('count badge shows 0 when no tasks', (tester) async {
      await tester.pumpWidget(_wrapColumn(db: db, status: 'todo'));
      await _settle(tester);
      expect(find.text('0'), findsOneWidget);
    });
  });

  // ── KanbanColumn task content ──────────────────────────────────────

  group('KanbanColumn – task content', () {
    testWidgets('description is shown on the card', (tester) async {
      await tester.pumpWidget(_wrapColumn(
        db: db,
        status: 'doing',
        tasks: [_makeTask(title: 'Fix', description: 'Close the issue')],
      ));
      await _settle(tester);
      expect(find.text('Close the issue'), findsOneWidget);
    });

    testWidgets('category chip appears when category matches task',
        (tester) async {
      final cat = Category(id: 1, name: 'Work', colorValue: 0xFF3B82F6);
      await tester.pumpWidget(_wrapColumn(
        db: db,
        status: 'todo',
        tasks: [
          _makeTask(id: 1, title: 'Report').copyWith(categoryId: const Value(1))
        ],
        categories: [cat],
      ));
      await _settle(tester);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('popup menu has Edit and Delete options', (tester) async {
      await tester.pumpWidget(_wrapColumn(
        db: db,
        status: 'todo',
        tasks: [_makeTask(title: 'Task')],
      ));
      await _settle(tester);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await _settle(tester);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });

  // ── KanbanColumn mutations ────────────────────────────────────────

  group('KanbanColumn – delete mutation', () {
    testWidgets('deleting a task removes it from the database', (tester) async {
      // Create the task outside FakeAsync to avoid microtask deadlock
      final id = await tester.runAsync(() => db.createTask(TasksCompanion(
            title: const Value('Kill me'),
            createdAt: Value(DateTime.now()),
          )));

      await tester.pumpWidget(_wrapColumn(
        db: db,
        status: 'todo',
        tasks: [_makeTask(id: id!, title: 'Kill me')],
      ));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.more_horiz));
      await _settle(tester);
      await tester.tap(find.text('Delete'));
      await _settle(tester);

      // Read DB outside FakeAsync
      final tasks = await _dbTasks(tester, db, 'todo');
      expect(tasks.any((t) => t.id == id), isFalse);
    });
  });

  // ── TaskFormSheet structure ────────────────────────────────────────

  group('TaskFormSheet – structure', () {
    testWidgets('shows "New task" title', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);
      expect(find.text('New task'), findsOneWidget);
    });

    testWidgets('shows "Edit task" title when task is provided', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db, task: _makeTask()));
      await _settle(tester);
      expect(find.text('Edit task'), findsOneWidget);
    });

    testWidgets('has a title input field', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);
      expect(find.widgetWithText(TextField, 'Task title'), findsOneWidget);
    });

    testWidgets('has a description input field', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);
      expect(find.widgetWithText(TextField, 'Description (optional)'),
          findsOneWidget);
    });

    testWidgets('all three status buttons are present', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);
      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('Doing'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('pre-fills title when task is provided', (tester) async {
      await tester.pumpWidget(
          _wrapForm(db: db, task: _makeTask(title: 'Pre-filled title')));
      await _settle(tester);
      expect(find.widgetWithText(TextField, 'Pre-filled title'), findsOneWidget);
    });

    testWidgets('pre-fills description when task is provided', (tester) async {
      await tester.pumpWidget(_wrapForm(
          db: db, task: _makeTask(title: 'T', description: 'Existing notes')));
      await _settle(tester);
      expect(
          find.widgetWithText(TextField, 'Existing notes'), findsOneWidget);
    });
  });

  // ── TaskFormSheet save behaviour ───────────────────────────────────

  group('TaskFormSheet – save behaviour', () {
    testWidgets('does not save when title is empty', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);

      await tester.tap(find.text('Create task'));
      await _settle(tester);

      final tasks = await _dbTasks(tester, db, 'todo');
      expect(tasks, isEmpty);
    });

    testWidgets('creates task in database with entered title', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Task title'), 'Form task');
      await _settle(tester);

      await tester.tap(find.text('Create task'));
      await _settle(tester);

      final tasks = await _dbTasks(tester, db, 'todo');
      expect(tasks.any((t) => t.title == 'Form task'), isTrue);
    });

    testWidgets('creates task with description', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Task title'), 'With desc');
      await tester.enterText(
          find.widgetWithText(TextField, 'Description (optional)'), 'Details');
      await _settle(tester);

      await tester.tap(find.text('Create task'));
      await _settle(tester);

      final tasks = await _dbTasks(tester, db, 'todo');
      final task = tasks.firstWhere((t) => t.title == 'With desc');
      expect(task.description, 'Details');
    });

    testWidgets('selecting Done status stores task as done', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Task title'), 'Done task');
      await tester.tap(find.text('Done'));
      await _settle(tester);

      await tester.tap(find.text('Create task'));
      await _settle(tester);

      final doneTasks = await _dbTasks(tester, db, 'done');
      expect(doneTasks.any((t) => t.title == 'Done task'), isTrue);
    });

    testWidgets('updates existing task title', (tester) async {
      final id = await tester.runAsync(() => db.createTask(TasksCompanion(
            title: const Value('Old'),
            createdAt: Value(DateTime.now()),
          )));

      await tester.pumpWidget(
          _wrapForm(db: db, task: _makeTask(id: id!, title: 'Old')));
      await _settle(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Old'), 'Updated');
      await _settle(tester);

      await tester.tap(find.text('Save changes'));
      await _settle(tester);

      final tasks = await _dbTasks(tester, db, 'todo');
      expect(tasks.any((t) => t.id == id && t.title == 'Updated'), isTrue);
    });
  });

  // ── Status selector ────────────────────────────────────────────────

  group('Status selector in TaskFormSheet', () {
    testWidgets('edit form shows "Edit task"', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db, task: _makeTask()));
      await _settle(tester);
      expect(find.text('Edit task'), findsOneWidget);
    });

    testWidgets('Doing status saves task as doing', (tester) async {
      await tester.pumpWidget(_wrapForm(db: db));
      await _settle(tester);

      await tester.enterText(
          find.widgetWithText(TextField, 'Task title'), 'Doing task');
      await tester.tap(find.text('Doing'));
      await _settle(tester);

      await tester.tap(find.text('Create task'));
      await _settle(tester);

      final doingTasks = await _dbTasks(tester, db, 'doing');
      expect(doingTasks.any((t) => t.title == 'Doing task'), isTrue);
    });
  });
}
