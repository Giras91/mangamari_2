import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart' show cacheDurationProvider;
import '../source_extensions/source_loader.dart';
import 'manga_details_view.dart';
import 'downloads_history_view.dart';

class HomeView extends ConsumerWidget {
            ExpansionTile(
              title: const Text('Cache Management'),
              children: [
                Row(
                  children: [
                    const Text('Cache Duration (min): '),
                    Consumer(
                      builder: (context, ref, _) {
                        final duration = ref.watch(cacheDurationProvider);
                        return SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: duration.toString()),
                            onSubmitted: (val) {
                              final mins = int.tryParse(val) ?? 5;
                              ref.read(cacheDurationProvider.notifier).state = mins;
                            },
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            final loader = SourceLoader();
                            loader.setCacheDuration(Duration(minutes: ref.read(cacheDurationProvider)));
                          },
                          child: const Text('Set'),
                        );
                      },
                    ),
                  ],
                ),
                Consumer(
                  builder: (context, ref, _) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: SourceLoader().getCacheInfo(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('Loading cache info...');
                        final info = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entries: ${info['count']}'),
                            Text('Oldest: ${info['oldest'] ?? '-'}'),
                            Text('Newest: ${info['newest'] ?? '-'}'),
                          ],
                        );
                      },
                    );
                  },
                ),
                Row(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            await SourceLoader().clearCache();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
                          },
                          child: const Text('Clear Cache'),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            await SourceLoader().refreshCache(
                              query: ref.read(searchQueryProvider),
                              category: ref.read(selectedCategoryProvider).name,
                              sourceType: ref.read(mangaSourceTypeProvider),
                              customEndpoint: ref.read(customEndpointProvider),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache refreshed')));
                          },
                          child: const Text('Refresh Cache'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final mangaListAsync = ref.watch(mangaListProvider);

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
              autofocus: true,
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
            Row(
              children: [
                const Text('Source: '),
                Consumer(
                  builder: (context, ref, _) {
                    final sourceType = ref.watch(mangaSourceTypeProvider);
                    return DropdownButton<MangaSourceType>(
                      value: sourceType,
                      items: MangaSourceType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (type) {
                        if (type != null) {
                          ref.read(mangaSourceTypeProvider.notifier).state = type;
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            ExpansionTile(
              title: const Text('Cache Management'),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Text('Cache Duration (min): '),
                    Consumer(
                      builder: (context, ref, _) {
                        final duration = ref.watch(cacheDurationProvider);
                        return SizedBox(
                          width: 60,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            controller: TextEditingController(text: duration.toString()),
                            onSubmitted: (val) {
                              final mins = int.tryParse(val) ?? 5;
                              ref.read(cacheDurationProvider.notifier).state = mins;
                            },
                          ),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            final loader = SourceLoader();
                            loader.setCacheDuration(Duration(minutes: ref.read(cacheDurationProvider)));
                          },
                          child: const Text('Set'),
                        );
                      },
                    ),
                  ],
                ),
                Consumer(
                  builder: (context, ref, _) {
                    return FutureBuilder<Map<String, dynamic>>(
                      future: SourceLoader().getCacheInfo(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('Loading cache info...');
                        final info = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Entries: ${info['count']}'),
                            Text('Oldest: ${info['oldest'] ?? '-'}'),
                            Text('Newest: ${info['newest'] ?? '-'}'),
                          ],
                        );
                      },
                    );
                  },
                ),
                Row(
                  children: <Widget>[
                    Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            await SourceLoader().clearCache();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
                          },
                          child: const Text('Clear Cache'),
                        );
                      },
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        return ElevatedButton(
                          onPressed: () async {
                            await SourceLoader().refreshCache(
                              query: ref.read(searchQueryProvider),
                              category: ref.read(selectedCategoryProvider).name,
                              sourceType: ref.read(mangaSourceTypeProvider),
                              customEndpoint: ref.read(customEndpointProvider),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache refreshed')));
                          },
                          child: const Text('Refresh Cache'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await SourceLoader().refreshCache(
                    query: ref.read(searchQueryProvider),
                    category: ref.read(selectedCategoryProvider).name,
                    sourceType: ref.read(mangaSourceTypeProvider),
                    customEndpoint: ref.read(customEndpointProvider),
                  );
                },
                child: mangaListAsync.when(
                  data: (mangas) => _MangaSection(
                    title: selectedCategory.name[0].toUpperCase() + selectedCategory.name.substring(1),
                    mangas: mangas,
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48, semanticLabel: 'Error icon'),
                        const SizedBox(height: 8),
                        Text('Error loading manga: $e', style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MangaSection extends StatelessWidget {
  static List<Widget> _buildComickDetails(String description) {
    final lines = description.split('\n');
    final widgets = <Widget>[];
    for (final line in lines) {
      if (line.startsWith('Author:')) {
        widgets.add(Text(line, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)));
      } else if (line.startsWith('Genres:')) {
        widgets.add(Text(line, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)));
      } else if (line.startsWith('Status:')) {
        widgets.add(Text(line, style: const TextStyle(fontSize: 12, color: Colors.green)));
      } else if (line.isNotEmpty && !line.startsWith('Author:') && !line.startsWith('Genres:') && !line.startsWith('Status:')) {
        widgets.add(Text(line, style: const TextStyle(fontSize: 12)));
      }
    }
    return widgets;
  }
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
                          if (manga.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ..._buildComickDetails(manga.description),
                          ],
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
