import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_viewmodel.dart';
import 'manga_details_view.dart';
import 'downloads_history_view.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final vm = ref.read(homeViewModelProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final filteredManga = vm.searchManga(searchQuery, selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MangaMari Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Downloads & History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DownloadsHistoryView(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search manga',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: MangaCategory.values.map((cat) {
                final label = cat.name[0].toUpperCase() + cat.name.substring(1);
                return ChoiceChip(
                  label: Text(label),
                  selected: selectedCategory == cat,
                  onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = cat,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _MangaSection(
                title: selectedCategory.name[0].toUpperCase() + selectedCategory.name.substring(1),
                mangas: filteredManga,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MangaSection extends StatelessWidget {
  final String title;
  final List mangas;
  const _MangaSection({required this.title, required this.mangas});

  @override
  Widget build(BuildContext context) {
    if (mangas.isEmpty) {
      return Center(child: Text('No manga found'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mangas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final manga = mangas[index];
              return GestureDetector(
                key: ValueKey(manga.title),
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => MangaDetailsView(manga: manga),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: Theme.of(context).colorScheme.surface,
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Placeholder for cover image
                          const SizedBox(
                            height: 80,
                            width: 80,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Icon(Icons.book, size: 40),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            manga.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
