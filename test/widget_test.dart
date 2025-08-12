  testWidgets('HomeView switches sources and shows custom endpoint field', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    // Open source dropdown and select 'custom'
    await tester.tap(find.byType(DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom').last);
    await tester.pumpAndSettle();
    // Custom endpoint field should appear
    expect(find.byType(TextField), findsWidgets); // At least two: search and endpoint
    expect(find.widgetWithText(TextField, 'Custom Endpoint URL'), findsOneWidget);
  });

  testWidgets('HomeView shows error on invalid custom endpoint', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    // Select custom source
    await tester.tap(find.byType(DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom').last);
    await tester.pumpAndSettle();
    // Enter invalid endpoint
    await tester.enterText(find.widgetWithText(TextField, 'Custom Endpoint URL'), 'https://invalid.endpoint');
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Error loading manga'), findsOneWidget);
  });

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangamari/views/home_view.dart';
import 'package:mangamari/views/manga_details_view.dart';
import 'package:mangamari/models/manga.dart';

void main() {
  testWidgets('HomeView displays category chips and search bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.widgetWithText(ChoiceChip, 'Latest'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Popular'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Trending'), findsOneWidget);
  });

  testWidgets('HomeView switches sources and shows custom endpoint field', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    await tester.tap(find.byType(DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom').last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsWidgets); // At least two: search and endpoint
    expect(find.widgetWithText(TextField, 'Custom Endpoint URL'), findsOneWidget);
  });

  testWidgets('HomeView shows error on invalid custom endpoint', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    await tester.tap(find.byType(DropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('custom').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Custom Endpoint URL'), 'https://invalid.endpoint');
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Error loading manga'), findsOneWidget);
  });

  testWidgets('MangaDetailsView displays manga info and chapters', (WidgetTester tester) async {
    final manga = Manga(
      title: 'Test Manga',
      coverUrl: '',
      description: 'A test manga description.',
      chapters: [
        Chapter(title: 'Chapter One', number: 1),
        Chapter(title: 'Chapter Two', number: 2),
      ],
    );
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: MangaDetailsView(manga: manga))));
    expect(find.text('Test Manga'), findsWidgets);
    expect(find.text('A test manga description.'), findsOneWidget);
    expect(find.text('Chapter 1: Chapter One'), findsOneWidget);
    expect(find.text('Chapter 2: Chapter Two'), findsOneWidget);
  });
}
