import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangamari/views/home_view.dart';
import 'package:mangamari/views/manga_details_view.dart';
import 'package:mangamari/models/manga.dart';
import 'package:mangamari/source_extensions/enhanced_source_loader.dart' show MangaSourceType;
import 'package:mangamari/viewmodels/home_viewmodel.dart' as vm;
import 'package:mangamari/viewmodels/home_viewmodel.dart' show mangaSourceTypeProvider;

void main() {
  setUpAll(() async {
    final dir = Directory('./test_hive');
    if (!dir.existsSync()) dir.createSync();
    Hive.init(dir.path);
    // Register Hive adapters here if needed
  });
  testWidgets('HomeView displays category chips and search bar', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.widgetWithText(ChoiceChip, 'Latest'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Popular'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Trending'), findsOneWidget);
  });

  testWidgets('HomeView switches sources and shows custom endpoint field', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vm.mangaListProvider.overrideWith((ref) async => <Manga>[]),
        mangaSourceTypeProvider.overrideWith((ref) => MangaSourceType.values.first),
      ],
      child: const MaterialApp(home: HomeView()),
    ));
    await tester.pumpAndSettle(); // Ensure widget tree is fully built
    debugDumpApp(); // Print widget tree to console
    final dropdownFinder = find.byKey(const Key('sourceDropdown'));
    debugPrint('DropdownButton widgets by key: ${tester.widgetList(dropdownFinder)}');
    expect(dropdownFinder, findsOneWidget);
    await tester.tap(dropdownFinder);
    await tester.pump();
    await tester.tap(find.text('custom').last);
    await tester.pump();
    expect(find.byType(TextField), findsWidgets); // At least two: search and endpoint
    expect(find.widgetWithText(TextField, 'Custom Endpoint URL'), findsOneWidget);
  });

  testWidgets('HomeView shows error on invalid custom endpoint', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vm.mangaListProvider.overrideWith((ref) async => throw Exception('Invalid endpoint')),
      ],
      child: const MaterialApp(home: HomeView()),
    ));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<MangaSourceType>));
    await tester.pump();
    await tester.tap(find.text('custom').last);
    await tester.pump();
    await tester.enterText(find.widgetWithText(TextField, 'Custom Endpoint URL'), 'https://invalid.endpoint');
    await tester.pump();
    expect(find.byKey(const Key('errorStateText')), findsOneWidget);
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

  // New widget tests for cache management, empty/error states, and accessibility
  testWidgets('HomeView shows cache management controls', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        // Mock cache info to resolve immediately
        vm.mangaListProvider.overrideWith((ref) async => <Manga>[]),
      ],
      child: const MaterialApp(home: HomeView()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cacheDurationDropdown')), findsOneWidget);
    expect(find.byKey(const Key('cacheRefreshButton')), findsOneWidget);
    expect(find.byKey(const Key('cacheInfoText')), findsOneWidget);
  });

  testWidgets('HomeView updates cache duration', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vm.mangaListProvider.overrideWith((ref) async => <Manga>[]),
      ],
      child: const MaterialApp(home: HomeView()),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const Key('cacheDurationDropdown')));
    await tester.pump();
    await tester.tap(find.text('60').last); // Select 60 minutes
    await tester.pump();
    // Check that dropdown now shows 60
    final dropdown = tester.widget<DropdownButton<int>>(find.byKey(const Key('cacheDurationDropdown')));
    expect(dropdown.value, 60);
  });  testWidgets('HomeView triggers cache refresh', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    await tester.tap(find.byKey(const Key('cacheRefreshButton')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('HomeView shows empty state when no manga', (WidgetTester tester) async {
    // Simulate empty manga list by overriding provider
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vm.mangaListProvider.overrideWith((ref) async => <Manga>[]),
      ],
      child: const MaterialApp(home: HomeView()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emptyStateText')), findsOneWidget);
  });

  testWidgets('HomeView shows error state on source error', (WidgetTester tester) async {
    // Simulate error by overriding provider
    await tester.pumpWidget(ProviderScope(
      overrides: [
        vm.mangaListProvider.overrideWith((ref) async => throw Exception('boom')),
      ],
      child: const MaterialApp(home: HomeView()),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('errorStateText')), findsOneWidget);
  });

  testWidgets('HomeView widgets have semantics labels', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: HomeView())));
    final searchField = find.byType(TextField).first;
    expect(tester.getSemantics(searchField), isNotNull);
    // Add more semantics checks as needed
  });
}
