import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../models/note.dart';
import '../models/calendar_event.dart';
import '../services/storage_service.dart';

class SearchScreen extends StatefulWidget {
  final StorageService storageService;
  
  const SearchScreen({super.key, required this.storageService});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final todos = widget.storageService.getAllTodos();
    final notes = widget.storageService.getAllNotes();
    final events = widget.storageService.getAllEvents();

    final results = <dynamic>[];

    // Search todos
    for (final todo in todos) {
      if (todo.title.toLowerCase().contains(query.toLowerCase()) ||
          (todo.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (todo.category?.toLowerCase().contains(query.toLowerCase()) ?? false)) {
        results.add({
          'type': 'todo',
          'data': todo,
          'title': todo.title,
          'subtitle': todo.description ?? 'No description',
        });
      }
    }

    // Search notes
    for (final note in notes) {
      if (note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.content.toLowerCase().contains(query.toLowerCase()) ||
          note.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))) {
        results.add({
          'type': 'note',
          'data': note,
          'title': note.title,
          'subtitle': note.content.length > 100 
              ? '${note.content.substring(0, 100)}...' 
              : note.content,
        });
      }
    }

    // Search events
    for (final event in events) {
      if (event.title.toLowerCase().contains(query.toLowerCase()) ||
          (event.description?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
          (event.location?.toLowerCase().contains(query.toLowerCase()) ?? false)) {
        results.add({
          'type': 'event',
          'data': event,
          'title': event.title,
          'subtitle': event.description ?? 'No description',
        });
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search todos, notes, and events...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: _performSearch,
              autofocus: true,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Everything',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Search through your todos, notes, and events',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: _buildTypeIcon(result['type']),
              title: Text(result['title']),
              subtitle: Text(result['subtitle']),
              trailing: _buildTypeChip(result['type']),
              onTap: () => _handleItemTap(result),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'todo':
        icon = Icons.task_alt_rounded;
        color = Theme.of(context).colorScheme.primary;
        break;
      case 'note':
        icon = Icons.note_rounded;
        color = Theme.of(context).colorScheme.secondary;
        break;
      case 'event':
        icon = Icons.event_rounded;
        color = Theme.of(context).colorScheme.tertiary;
        break;
      default:
        icon = Icons.help_rounded;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildTypeChip(String type) {
    String label;
    Color color;

    switch (type) {
      case 'todo':
        label = 'Todo';
        color = Theme.of(context).colorScheme.primary;
        break;
      case 'note':
        label = 'Note';
        color = Theme.of(context).colorScheme.secondary;
        break;
      case 'event':
        label = 'Event';
        color = Theme.of(context).colorScheme.tertiary;
        break;
      default:
        label = 'Unknown';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleItemTap(Map<String, dynamic> result) {
    // In a real app, you would navigate to the appropriate screen
    // and highlight the specific item
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${result['type'].toUpperCase()}: ${result['title']}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Navigate to the item
          },
        ),
      ),
    );
  }
}
