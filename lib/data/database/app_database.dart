import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get colorValue => integer()();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  // 'todo' | 'doing' | 'done'
  TextColumn get status => text().withDefault(const Constant('todo'))();
  IntColumn get categoryId => integer().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Tasks, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'aline_db',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.dart.js'),
        ),
      );

  // ── Tasks ───────────────────────────────────────────────────

  Stream<List<Task>> watchTasksByStatus(String status) {
    return (select(tasks)
          ..where((t) => t.status.equals(status))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .watch();
  }

  /// Returns tasks grouped by normalised date (time stripped).
  Stream<Map<DateTime, List<Task>>> watchTasksWithDates() {
    return select(tasks).watch().map((list) {
      final map = <DateTime, List<Task>>{};
      for (final task in list) {
        if (task.dueDate != null) {
          final key = DateTime(
            task.dueDate!.year,
            task.dueDate!.month,
            task.dueDate!.day,
          );
          map.putIfAbsent(key, () => []).add(task);
        }
      }
      return map;
    });
  }

  Future<int> createTask(TasksCompanion companion) =>
      into(tasks).insert(companion);

  Future<void> updateTask({
    required int id,
    required String title,
    String? description,
    required String status,
    int? categoryId,
    DateTime? dueDate,
  }) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(title),
        description: Value(description),
        status: Value(status),
        categoryId: Value(categoryId),
        dueDate: Value(dueDate),
      ),
    );
  }

  Future<void> updateTaskStatus(int id, String status) {
    return (update(tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(status: Value(status)));
  }

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  // ── Categories ──────────────────────────────────────────────

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<int> createCategory(String name, int colorValue) =>
      into(categories).insert(
        CategoriesCompanion(
          name: Value(name),
          colorValue: Value(colorValue),
        ),
      );

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();
}
