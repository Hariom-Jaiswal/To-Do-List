import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  final StorageService storageService;
  final VoidCallback? onNavigateToCalendar;
  final VoidCallback? onNavigateToTodos;
  final VoidCallback? onNavigateToNotes;
  final VoidCallback? onNavigateToSearch;
  
  const DashboardScreen({
    super.key, 
    required this.storageService,
    this.onNavigateToCalendar,
    this.onNavigateToTodos,
    this.onNavigateToNotes,
    this.onNavigateToSearch,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, int> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    
    // Listen to data changes
    widget.storageService.addTodosListener(_loadStatistics);
    widget.storageService.addNotesListener(_loadStatistics);
    widget.storageService.addEventsListener(_loadStatistics);
  }

  @override
  void dispose() {
    widget.storageService.removeTodosListener(_loadStatistics);
    widget.storageService.removeNotesListener(_loadStatistics);
    widget.storageService.removeEventsListener(_loadStatistics);
    super.dispose();
  }

  void _loadStatistics() {
    setState(() {
      _statistics = widget.storageService.getStatistics();
      _isLoading = false;
    });
  }

  void _showQuickAddDialog(String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              type == 'Todo' ? Icons.add_task_rounded :
              type == 'Event' ? Icons.event_rounded :
              Icons.note_add_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text('Quick Add $type'),
          ],
        ),
        content: Text(
          'This will open the $type screen where you can add a new $type. Would you like to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (type == 'Todo') {
                widget.onNavigateToTodos?.call();
              } else if (type == 'Event') {
                widget.onNavigateToCalendar?.call();
              } else if (type == 'Note') {
                widget.onNavigateToNotes?.call();
              }
            },
            child: Text('Go to $type'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              setState(() {
                _isLoading = true;
              });
              await widget.storageService.refreshData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),
                  _buildStatisticsGrid(),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.waving_hand_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Ready to be productive?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    '${_statistics['todayEvents'] ?? 0}',
                    'Events Today',
                    Icons.event_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickStat(
                    '${_statistics['pendingTodos'] ?? 0}',
                    'Pending Tasks',
                    Icons.task_alt_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total Todos',
              '${_statistics['totalTodos'] ?? 0}',
              Icons.task_alt_rounded,
              Theme.of(context).colorScheme.primary,
            ),
            _buildStatCard(
              'Completed',
              '${_statistics['completedTodos'] ?? 0}',
              Icons.check_circle_rounded,
              Colors.green,
            ),
            _buildStatCard(
              'Pending',
              '${_statistics['pendingTodos'] ?? 0}',
              Icons.schedule_rounded,
              Colors.orange,
            ),
            _buildStatCard(
              'Overdue',
              '${_statistics['overdueTodos'] ?? 0}',
              Icons.warning_rounded,
              Colors.red,
            ),
            _buildStatCard(
              'Notes',
              '${_statistics['totalNotes'] ?? 0}',
              Icons.note_rounded,
              Theme.of(context).colorScheme.secondary,
            ),
            _buildStatCard(
              'Events',
              '${_statistics['totalEvents'] ?? 0}',
              Icons.event_rounded,
              Theme.of(context).colorScheme.tertiary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Todo',
                Icons.add_task_rounded,
                Theme.of(context).colorScheme.primary,
                () {
                  _showQuickAddDialog('Todo');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Add Event',
                Icons.event_rounded,
                Theme.of(context).colorScheme.secondary,
                () {
                  _showQuickAddDialog('Event');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Add Note',
                Icons.note_add_rounded,
                Theme.of(context).colorScheme.tertiary,
                () {
                  _showQuickAddDialog('Note');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Search',
                Icons.search_rounded,
                Colors.grey,
                () {
                  widget.onNavigateToSearch?.call();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
