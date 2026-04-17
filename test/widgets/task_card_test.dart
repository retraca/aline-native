import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aline_native/data/database/app_database.dart';
import 'package:aline_native/features/board/widgets/task_card.dart';

// Helper — builds a Task data class inline without hitting the DB.
Task _task({
  int id = 1,
  String title = 'Test task',
  String? description,
  String status = 'todo',
  int? categoryId,
  DateTime? dueDate,
}) {
  return Task(
    id: id,
    title: title,
    description: description,
    status: status,
    categoryId: categoryId,
    dueDate: dueDate,
    createdAt: DateTime(2025, 1, 1),
    position: 0,
  );
}

Category _category({
  int id = 1,
  String name = 'Work',
  int colorValue = 0xFF3B82F6,
}) {
  return Category(id: id, name: name, colorValue: colorValue);
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('TaskCard', () {
    testWidgets('displays the task title', (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(title: 'Buy groceries'),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.text('Buy groceries'), findsOneWidget);
    });

    testWidgets('displays description when present', (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(description: 'From the list'),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.text('From the list'), findsOneWidget);
    });

    testWidgets('shows no description text when null', (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(description: null),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      // Only the title should be visible, no empty description widget
      expect(find.text(''), findsNothing);
    });

    testWidgets('displays category name chip when category is provided',
        (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(categoryId: 1),
        category: _category(name: 'Work'),
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('does not show category chip when category is null',
        (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.text('Work'), findsNothing);
    });

    testWidgets('displays due date chip when dueDate is set', (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(dueDate: DateTime(2025, 12, 25)),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.textContaining('Dec'), findsOneWidget);
      expect(find.textContaining('25'), findsOneWidget);
    });

    testWidgets('no due date chip when dueDate is null', (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(dueDate: null),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.byIcon(Icons.calendar_today_outlined), findsNothing);
    });

    testWidgets('tapping card calls onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(),
        category: null,
        onTap: () => tapped = true,
        onDelete: () {},
      )));
      await tester.tap(find.byType(TaskCard));
      expect(tapped, isTrue);
    });

    testWidgets('popup menu has Edit and Delete options', (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(),
        category: null,
        onTap: () {},
        onDelete: () {},
      )));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('delete from popup calls onDelete', (tester) async {
      var deleted = false;
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(),
        category: null,
        onTap: () {},
        onDelete: () => deleted = true,
      )));
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('both category and due date shown when both present',
        (tester) async {
      await tester.pumpWidget(_wrap(TaskCard(
        task: _task(dueDate: DateTime(2025, 6, 1), categoryId: 1),
        category: _category(name: 'Personal'),
        onTap: () {},
        onDelete: () {},
      )));
      expect(find.text('Personal'), findsOneWidget);
      expect(find.textContaining('Jun'), findsOneWidget);
    });
  });
}
