import 'package:flutter/material.dart';

class ChapterListView extends StatelessWidget {
  final List<String> chapters;
  final void Function(String) onChapterTap;

  const ChapterListView({
    super.key,
    required this.chapters,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('chapter-list'),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return ListTile(
          key: ValueKey('chapter-$chapter'),
          title: Text('Chapter $chapter'),
          trailing: IconButton(
            key: ValueKey('chapter-read-$chapter'),
            icon: const Icon(Icons.menu_book),
            onPressed: () => onChapterTap(chapter),
          ),
        );
      },
    );
  }
}
