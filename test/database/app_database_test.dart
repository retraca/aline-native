import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aline_native/data/database/app_database.dart';

AppDatabase _makeDb() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;

  setUp(() => db = _makeDb());
  tearDown(() => db.close());

  // ── Tasks ──────────────────────────────────────────────────────────

  group('Task creation', () {
    test('returns a positive id', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Buy milk'),
        createdAt: Value(DateTime.now()),
      ));
      expect(id, greaterThan(0));
    });

    test('new task defaults to todo status', () async {
      await db.createTask(TasksCompanion(
        title: const Value('Default status'),
        createdAt: Value(DateTime.now()),
      ));
      final tasks = await db.watchTasksByStatus('todo').first;
      expect(tasks.any((t) => t.title == 'Default status'), isTrue);
    });

    test('explicit status is stored correctly', () async {
      await db.createTask(TasksCompanion(
        title: const Value('In progress'),
        status: const Value('doing'),
        createdAt: Value(DateTime.now()),
      ));
      final doing = await db.watchTasksByStatus('doing').first;
      expect(doing.any((t) => t.title == 'In progress'), isTrue);
      final todo = await db.watchTasksByStatus('todo').first;
      expect(todo.any((t) => t.title == 'In progress'), isFalse);
    });

    test('description is stored and retrieved', () async {
      await db.createTask(TasksCompanion(
        title: const Value('With desc'),
        description: const Value('Some notes'),
        createdAt: Value(DateTime.now()),
      ));
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.title == 'With desc');
      expect(task.description, 'Some notes');
    });

    test('null description stays null', () async {
      await db.createTask(TasksCompanion(
        title: const Value('No desc'),
        createdAt: Value(DateTime.now()),
      ));
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.title == 'No desc');
      expect(task.description, isNull);
    });

    test('due date round-trips without loss of precision to the second', () async {
      final due = DateTime(2025, 6, 15, 9, 30);
      await db.createTask(TasksCompanion(
        title: const Value('Dated'),
        dueDate: Value(due),
        createdAt: Value(DateTime.now()),
      ));
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.title == 'Dated');
      expect(task.dueDate?.year, 2025);
      expect(task.dueDate?.month, 6);
      expect(task.dueDate?.day, 15);
    });
  });

  group('Task status update', () {
    test('moves task from todo to doing', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Move me'),
        createdAt: Value(DateTime.now()),
      ));
      await db.updateTaskStatus(id, 'doing');

      final todo = await db.watchTasksByStatus('todo').first;
      final doing = await db.watchTasksByStatus('doing').first;

      expect(todo.any((t) => t.id == id), isFalse);
      expect(doing.any((t) => t.id == id), isTrue);
    });

    test('moves task through all statuses', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Full journey'),
        createdAt: Value(DateTime.now()),
      ));

      await db.updateTaskStatus(id, 'doing');
      var tasks = await db.watchTasksByStatus('doing').first;
      expect(tasks.any((t) => t.id == id), isTrue);

      await db.updateTaskStatus(id, 'done');
      tasks = await db.watchTasksByStatus('done').first;
      expect(tasks.any((t) => t.id == id), isTrue);
    });
  });

  group('Task full update', () {
    test('updates title and description', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Old title'),
        createdAt: Value(DateTime.now()),
      ));
      await db.updateTask(
        id: id,
        title: 'New title',
        description: 'New desc',
        status: 'todo',
      );
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.id == id);
      expect(task.title, 'New title');
      expect(task.description, 'New desc');
    });

    test('clears description when null is passed', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Has desc'),
        description: const Value('Remove me'),
        createdAt: Value(DateTime.now()),
      ));
      await db.updateTask(
        id: id,
        title: 'Has desc',
        description: null,
        status: 'todo',
      );
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.id == id);
      expect(task.description, isNull);
    });

    test('updates due date', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Reschedule'),
        createdAt: Value(DateTime.now()),
      ));
      final newDate = DateTime(2026, 1, 20);
      await db.updateTask(
        id: id,
        title: 'Reschedule',
        status: 'todo',
        dueDate: newDate,
      );
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.id == id);
      expect(task.dueDate?.day, 20);
      expect(task.dueDate?.month, 1);
    });
  });

  group('Task deletion', () {
    test('deleted task no longer appears in stream', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Delete me'),
        createdAt: Value(DateTime.now()),
      ));
      await db.deleteTask(id);
      final tasks = await db.watchTasksByStatus('todo').first;
      expect(tasks.any((t) => t.id == id), isFalse);
    });

    test('deleting one task does not remove others', () async {
      final id1 = await db.createTask(TasksCompanion(
        title: const Value('Keep me'),
        createdAt: Value(DateTime.now()),
      ));
      final id2 = await db.createTask(TasksCompanion(
        title: const Value('Remove me'),
        createdAt: Value(DateTime.now()),
      ));
      await db.deleteTask(id2);
      final tasks = await db.watchTasksByStatus('todo').first;
      expect(tasks.any((t) => t.id == id1), isTrue);
      expect(tasks.any((t) => t.id == id2), isFalse);
    });
  });

  group('watchTasksByStatus ordering', () {
    test('tasks are returned in position order', () async {
      await db.createTask(TasksCompanion(
        title: const Value('Position 2'),
        position: const Value(2),
        createdAt: Value(DateTime.now()),
      ));
      await db.createTask(TasksCompanion(
        title: const Value('Position 0'),
        position: const Value(0),
        createdAt: Value(DateTime.now()),
      ));
      await db.createTask(TasksCompanion(
        title: const Value('Position 1'),
        position: const Value(1),
        createdAt: Value(DateTime.now()),
      ));
      final tasks = await db.watchTasksByStatus('todo').first;
      expect(tasks[0].title, 'Position 0');
      expect(tasks[1].title, 'Position 1');
      expect(tasks[2].title, 'Position 2');
    });
  });

  // ── watchTasksWithDates ───────────────────────────────────────────

  group('watchTasksWithDates', () {
    test('task with due date appears in map', () async {
      final due = DateTime(2025, 3, 10);
      await db.createTask(TasksCompanion(
        title: const Value('Due task'),
        dueDate: Value(due),
        createdAt: Value(DateTime.now()),
      ));
      final map = await db.watchTasksWithDates().first;
      final key = DateTime(2025, 3, 10);
      expect(map.containsKey(key), isTrue);
      expect(map[key]!.any((t) => t.title == 'Due task'), isTrue);
    });

    test('task without due date does not appear in map', () async {
      await db.createTask(TasksCompanion(
        title: const Value('No date'),
        createdAt: Value(DateTime.now()),
      ));
      final map = await db.watchTasksWithDates().first;
      final allTasks = map.values.expand((l) => l);
      expect(allTasks.any((t) => t.title == 'No date'), isFalse);
    });

    test('multiple tasks on same day are grouped together', () async {
      final due = DateTime(2025, 5, 1);
      await db.createTask(TasksCompanion(
        title: const Value('Morning'),
        dueDate: Value(due),
        createdAt: Value(DateTime.now()),
      ));
      await db.createTask(TasksCompanion(
        title: const Value('Afternoon'),
        dueDate: Value(due),
        createdAt: Value(DateTime.now()),
      ));
      final map = await db.watchTasksWithDates().first;
      final key = DateTime(2025, 5, 1);
      expect(map[key]!.length, 2);
    });

    test('tasks on different days are in separate buckets', () async {
      await db.createTask(TasksCompanion(
        title: const Value('Day 1'),
        dueDate: Value(DateTime(2025, 7, 1)),
        createdAt: Value(DateTime.now()),
      ));
      await db.createTask(TasksCompanion(
        title: const Value('Day 2'),
        dueDate: Value(DateTime(2025, 7, 2)),
        createdAt: Value(DateTime.now()),
      ));
      final map = await db.watchTasksWithDates().first;
      expect(map[DateTime(2025, 7, 1)]!.length, 1);
      expect(map[DateTime(2025, 7, 2)]!.length, 1);
    });
  });

  // ── Categories ────────────────────────────────────────────────────

  group('Category creation', () {
    test('creates a category with name and color', () async {
      final id = await db.createCategory('Work', 0xFF3B82F6);
      expect(id, greaterThan(0));
      final cats = await db.watchAllCategories().first;
      expect(cats.any((c) => c.name == 'Work'), isTrue);
    });

    test('color value is stored exactly', () async {
      await db.createCategory('Purple', 0xFF8B5CF6);
      final cats = await db.watchAllCategories().first;
      final cat = cats.firstWhere((c) => c.name == 'Purple');
      expect(cat.colorValue, 0xFF8B5CF6);
    });

    test('multiple categories are all returned', () async {
      await db.createCategory('A', 0xFFEF4444);
      await db.createCategory('B', 0xFF22C55E);
      await db.createCategory('C', 0xFF3B82F6);
      final cats = await db.watchAllCategories().first;
      expect(cats.length, 3);
    });
  });

  group('Category deletion', () {
    test('deleted category no longer appears', () async {
      final id = await db.createCategory('Temp', 0xFF000000);
      await db.deleteCategory(id);
      final cats = await db.watchAllCategories().first;
      expect(cats.any((c) => c.id == id), isFalse);
    });
  });

  group('Category association', () {
    test('task can be associated with a category', () async {
      final catId = await db.createCategory('Personal', 0xFF10B981);
      await db.createTask(TasksCompanion(
        title: const Value('Grocery run'),
        categoryId: Value(catId),
        createdAt: Value(DateTime.now()),
      ));
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.title == 'Grocery run');
      expect(task.categoryId, catId);
    });

    test('category association can be updated', () async {
      final catId = await db.createCategory('Work', 0xFF3B82F6);
      final taskId = await db.createTask(TasksCompanion(
        title: const Value('Report'),
        createdAt: Value(DateTime.now()),
      ));
      await db.updateTask(
        id: taskId,
        title: 'Report',
        status: 'todo',
        categoryId: catId,
      );
      final tasks = await db.watchTasksByStatus('todo').first;
      final task = tasks.firstWhere((t) => t.id == taskId);
      expect(task.categoryId, catId);
    });
  });

  // ── Stream reactivity ─────────────────────────────────────────────

  group('Stream reactivity', () {
    test('watchTasksByStatus emits new value after insert', () async {
      final stream = db.watchTasksByStatus('todo');
      // First emission: empty
      expect(await stream.first, isEmpty);

      await db.createTask(TasksCompanion(
        title: const Value('Reactive task'),
        createdAt: Value(DateTime.now()),
      ));

      // After insert, stream should emit updated list
      final second = await stream.first;
      expect(second.any((t) => t.title == 'Reactive task'), isTrue);
    });

    test('watchTasksByStatus emits after status change', () async {
      final id = await db.createTask(TasksCompanion(
        title: const Value('Watch me move'),
        createdAt: Value(DateTime.now()),
      ));

      var todoTasks = await db.watchTasksByStatus('todo').first;
      expect(todoTasks.any((t) => t.id == id), isTrue);

      await db.updateTaskStatus(id, 'done');

      todoTasks = await db.watchTasksByStatus('todo').first;
      expect(todoTasks.any((t) => t.id == id), isFalse);

      final doneTasks = await db.watchTasksByStatus('done').first;
      expect(doneTasks.any((t) => t.id == id), isTrue);
    });
  });
}
