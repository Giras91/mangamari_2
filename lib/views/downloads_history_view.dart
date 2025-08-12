import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/home_viewmodel.dart';

class DownloadsHistoryView extends ConsumerWidget {
  const DownloadsHistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider);
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads & History')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloaded Chapters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            downloads.isEmpty
                ? const Text('No downloads yet.')
                : Expanded(
                    child: ListView.separated(
                      itemCount: downloads.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final id = downloads.elementAt(index);
                        return ListTile(
                          key: ValueKey('download-$id'),
                          leading: const Icon(Icons.download_done),
                          title: Text(id, style: Theme.of(context).textTheme.bodyLarge),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),
            Text('Reading History', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            history.isEmpty
                ? const Text('No history yet.')
                : Expanded(
                    child: ListView.separated(
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final id = history[index];
                        return ListTile(
                          key: ValueKey('history-$id'),
                          leading: const Icon(Icons.history),
                          title: Text(id, style: Theme.of(context).textTheme.bodyLarge),
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
