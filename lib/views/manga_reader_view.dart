import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manga.dart';
import '../viewmodels/home_viewmodel.dart';

class MangaReaderView extends ConsumerStatefulWidget {
  final Manga manga;
  final Chapter chapter;
  const MangaReaderView({required this.manga, required this.chapter, super.key});

  @override
  ConsumerState<MangaReaderView> createState() => _MangaReaderViewState();
}

class _MangaReaderViewState extends ConsumerState<MangaReaderView> {
  bool vertical = true;
  bool ltr = true;
  double zoom = 1.0;

  @override
  void initState() {
    super.initState();
    final chapterId = '${widget.manga.title}-${widget.chapter.number}';
    ref.read(historyProvider.notifier).add(chapterId);
  }

  @override
  Widget build(BuildContext context) {
    final chapterId = '${widget.manga.title}-${widget.chapter.number}';
    final downloads = ref.watch(downloadsProvider);
    final isDownloaded = downloads.contains(chapterId);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.manga.title} - ${widget.chapter.title}'),
        actions: [
          IconButton(
            icon: Icon(isDownloaded ? Icons.download_done : Icons.download),
            tooltip: 'Download chapter',
            onPressed: () => ref.read(downloadsProvider.notifier).add(chapterId),
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(vertical ? Icons.view_agenda : Icons.view_carousel),
                tooltip: 'Toggle scroll direction',
                onPressed: () => setState(() => vertical = !vertical),
              ),
              IconButton(
                icon: Icon(ltr ? Icons.format_textdirection_l_to_r : Icons.format_textdirection_r_to_l),
                tooltip: 'Toggle reading direction',
                onPressed: () => setState(() => ltr = !ltr),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom in',
                onPressed: () => setState(() => zoom += 0.1),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out),
                tooltip: 'Zoom out',
                onPressed: () => setState(() => zoom = (zoom - 0.1).clamp(1.0, 3.0)),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Transform.scale(
                scale: zoom,
                child: Container(
                  key: ValueKey(widget.chapter.title),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: widget.chapter.title.isEmpty
                      ? const CircularProgressIndicator()
                      : Text(
                          'Reader mock: ${widget.chapter.title}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
