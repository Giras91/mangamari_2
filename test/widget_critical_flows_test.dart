
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangamari/views/chapter_list_view.dart';
import 'package:mangamari/views/reader_view.dart';
import 'package:mangamari/views/favorites_view.dart';
import 'package:mangamari/views/settings_view.dart';
import 'package:mangamari/views/source_manager_view.dart';

void main() {
  testWidgets('SourceManagerView interactive widgets have keys', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SourceManagerView()));
    // AppBar buttons
    expect(find.byKey(const ValueKey('settingsButton')), findsOneWidget);
    expect(find.byKey(const ValueKey('installButton')), findsOneWidget);
    // Empty state install button (if no sources)
    expect(find.byKey(const ValueKey('installSourceButton')), findsWidgets);
    // Open install dialog and check dialog widgets
    await tester.tap(find.byKey(const ValueKey('installButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('installDialogCancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('installDialogConfirm')), findsOneWidget);
    expect(find.byKey(const ValueKey('installUrlField')), findsOneWidget);
    expect(find.byKey(const ValueKey('installJsonField')), findsOneWidget);
    // Open compliance dialog and check dialog widgets
    await tester.tap(find.byKey(const ValueKey('settingsButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('complianceCancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('complianceSave')), findsOneWidget);
    expect(find.byKey(const ValueKey('complianceUnknownSwitch')), findsOneWidget);
    expect(find.byKey(const ValueKey('complianceUnsafeSwitch')), findsOneWidget);
    expect(find.byKey(const ValueKey('complianceWarningSwitch')), findsOneWidget);
  });
  testWidgets('ChapterListView displays chapters and responds to tap', (WidgetTester tester) async {
    String tappedChapter = '';
    await tester.pumpWidget(MaterialApp(
      home: ChapterListView(
        chapters: ['1', '2'],
        onChapterTap: (chapter) => tappedChapter = chapter,
      ),
    ));
    expect(find.byKey(const ValueKey('chapter-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('chapter-2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chapter-read-1')));
    expect(tappedChapter, '1');
  });

  testWidgets('ReaderView displays chapter and responds to actions', (WidgetTester tester) async {
    bool toggled = false;
    bool bookmarked = false;
    await tester.pumpWidget(MaterialApp(
      home: ReaderView(
        chapterId: '1',
        onToggleMode: () => toggled = true,
        onBookmark: () => bookmarked = true,
      ),
    ));
    expect(find.byKey(const ValueKey('reader-chapter-text')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('reader-toggle-mode')));
    expect(toggled, true);
    await tester.tap(find.byKey(const ValueKey('reader-bookmark')));
    expect(bookmarked, true);
  });

  testWidgets('FavoritesView displays favorites and removes on tap', (WidgetTester tester) async {
    List<String> favs = ['Naruto', 'Bleach'];
    await tester.pumpWidget(MaterialApp(
      home: FavoritesView(
        favorites: favs,
        onRemove: (manga) => favs.remove(manga),
      ),
    ));
    expect(find.byKey(const ValueKey('favorites-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('favorite-Naruto')), findsOneWidget);
    expect(find.byKey(const ValueKey('favorite-Bleach')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('favorite-remove-Naruto')));
    expect(favs.contains('Naruto'), false);
  });

  testWidgets('SettingsView interactive widgets have keys', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsView()));
    expect(find.byKey(const ValueKey('settings-manage-sources')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-ai-source-generator')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-theme')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-reader-settings')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-downloads')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-clear-cache')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-about')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-legal')), findsOneWidget);
  });
}
