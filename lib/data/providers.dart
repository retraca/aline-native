import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';

export 'database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final todoTasksProvider = StreamProvider<List<Task>>((ref) =>
    ref.watch(databaseProvider).watchTasksByStatus('todo'));

final doingTasksProvider = StreamProvider<List<Task>>((ref) =>
    ref.watch(databaseProvider).watchTasksByStatus('doing'));

final doneTasksProvider = StreamProvider<List<Task>>((ref) =>
    ref.watch(databaseProvider).watchTasksByStatus('done'));

final allCategoriesProvider = StreamProvider<List<Category>>((ref) =>
    ref.watch(databaseProvider).watchAllCategories());

final tasksWithDatesProvider =
    StreamProvider<Map<DateTime, List<Task>>>(
        (ref) => ref.watch(databaseProvider).watchTasksWithDates());

final selectedDateProvider = StateProvider<DateTime>(
  (ref) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  },
);
