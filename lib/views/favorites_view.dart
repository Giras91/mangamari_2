import 'package:flutter/material.dart';

class FavoritesView extends StatelessWidget {
  final List<String> favorites;
  final void Function(String) onRemove;

  const FavoritesView({
    super.key,
    required this.favorites,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const ValueKey('favorites-list'),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final manga = favorites[index];
        return ListTile(
          key: ValueKey('favorite-$manga'),
          title: Text(manga),
          trailing: IconButton(
            key: ValueKey('favorite-remove-$manga'),
            icon: const Icon(Icons.delete),
            onPressed: () => onRemove(manga),
          ),
        );
      },
    );
  }
}
