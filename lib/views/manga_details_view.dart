import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../viewmodels/home_viewmodel.dart';
import 'manga_reader_view.dart';

class MangaDetailsView extends ConsumerWidget {
  final Manga manga;
  const MangaDetailsView({required this.manga, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final favorites = ref.read(favoritesProvider);
  final isFavorite = favorites.contains(manga.title);
    return Scaffold(
      appBar: AppBar(
        title: Text(manga.title),
        actions: [
          IconButton(
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: () => ref.read(favoritesProvider.notifier).toggle(manga.title),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image placeholder
            Container(
              height: 160,
              width: 120,
              color: Colors.grey[300],
              child: const Icon(Icons.book, size: 60),
            ),
            const SizedBox(height: 16),
            Text(manga.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(manga.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            Text('Chapters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: manga.chapters.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: manga.chapters.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chapter = manga.chapters[index];
                        final chapterId = '${manga.title}-${chapter.number}';
                        final bookmarks = ref.watch(bookmarksProvider);
                        final isBookmarked = bookmarks.contains(chapterId);
                        return ListTile(
                          key: ValueKey(chapterId),
                          title: Text('Chapter ${chapter.number}: ${chapter.title}', style: Theme.of(context).textTheme.bodyLarge),
                          trailing: IconButton(
                            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                            onPressed: () => ref.read(bookmarksProvider.notifier).toggle(chapterId),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                pageBuilder: (_, __, ___) => MangaReaderView(manga: manga, chapter: chapter),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
