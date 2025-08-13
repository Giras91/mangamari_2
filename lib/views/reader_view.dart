import 'package:flutter/material.dart';

class ReaderView extends StatelessWidget {
  final String chapterId;
  final VoidCallback onToggleMode;
  final VoidCallback onBookmark;

  const ReaderView({
    super.key,
    required this.chapterId,
    required this.onToggleMode,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reader - Chapter $chapterId'),
        actions: [
          IconButton(
            key: const ValueKey('reader-toggle-mode'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: onToggleMode,
          ),
          IconButton(
            key: const ValueKey('reader-bookmark'),
            icon: const Icon(Icons.bookmark),
            onPressed: onBookmark,
          ),
        ],
      ),
      body: Center(
        child: Text('Reading Chapter $chapterId', key: const ValueKey('reader-chapter-text')),
      ),
    );
  }
}
