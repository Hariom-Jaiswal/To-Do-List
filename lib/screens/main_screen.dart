import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'calendar_screen.dart';
import 'notes_screen.dart';
import 'todo_screen.dart';
import 'dashboard_screen.dart';
import 'search_screen.dart';

class MainScreen extends StatefulWidget {
  final StorageService storageService;
  
  const MainScreen({super.key, required this.storageService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(
        storageService: widget.storageService,
        onNavigateToCalendar: () => _navigateToTab(1),
        onNavigateToTodos: () => _navigateToTab(2),
        onNavigateToNotes: () => _navigateToTab(3),
        onNavigateToSearch: () => _navigateToTab(4),
      ),
      CalendarScreen(storageService: widget.storageService),
      TodoScreen(storageService: widget.storageService),
      NotesScreen(storageService: widget.storageService),
    ];
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex < _screens.length && _currentIndex != 0
          ? _buildAppBar() 
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        child: Container(
          key: ValueKey<int>(_currentIndex),
          child: _currentIndex < _screens.length 
              ? _screens[_currentIndex]
              : _buildExtraScreens(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildNavItem(1, Icons.calendar_today_rounded, 'Calendar'),
                _buildNavItem(2, Icons.task_alt_rounded, 'Todos'),
                _buildNavItem(3, Icons.note_rounded, 'Notes'),
                _buildNavItem(4, Icons.search_rounded, 'Search'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ) ?? const TextStyle(),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_getAppBarTitle()),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        if (_currentIndex == 0) // Dashboard
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              await widget.storageService.refreshData();
            },
          ),
        if (_currentIndex == 4) // Search
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {
              // Show search filters
            },
          ),
      ],
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Calendar';
      case 2:
        return 'Todos';
      case 3:
        return 'Notes';
      case 4:
        return 'Search';
      default:
        return 'Calendar Plus';
    }
  }

  Widget _buildExtraScreens() {
    switch (_currentIndex) {
      case 4:
        return SearchScreen(storageService: widget.storageService);
      default:
        return const Center(child: Text('Screen not found'));
    }
  }
}
