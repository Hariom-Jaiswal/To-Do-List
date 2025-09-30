import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';
import '../services/storage_service.dart';

class TodoScreen extends StatefulWidget {
  final StorageService storageService;
  
  const TodoScreen({super.key, required this.storageService});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  List<Todo> _todos = [];
  String _filter = 'all'; // 'all', 'pending', 'completed', 'overdue'
  String _sortBy = 'dueDate'; // 'dueDate', 'priority', 'createdAt'

  @override
  void initState() {
    super.initState();
    _loadTodos();
    
    // Listen to data changes
    widget.storageService.addTodosListener(_loadTodos);
  }

  @override
  void dispose() {
    widget.storageService.removeTodosListener(_loadTodos);
    super.dispose();
  }

  void _loadTodos() async {
    await widget.storageService.initializeData();
    if (mounted) {
      setState(() {
        _todos = widget.storageService.getAllTodos();
      });
    }
  }

  List<Todo> get _filteredTodos {
    var filtered = _todos;

    // Apply filter
    switch (_filter) {
      case 'pending':
        filtered = filtered.where((todo) => !todo.isCompleted).toList();
        break;
      case 'completed':
        filtered = filtered.where((todo) => todo.isCompleted).toList();
        break;
      case 'overdue':
        final now = DateTime.now();
        filtered = filtered.where((todo) => 
            !todo.isCompleted && 
            todo.dueDate != null && 
            todo.dueDate!.isBefore(now)).toList();
        break;
    }

    // Apply sorting
    switch (_sortBy) {
      case 'dueDate':
        filtered.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'priority':
        final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
        filtered.sort((a, b) => 
            (priorityOrder[b.priority] ?? 0).compareTo(priorityOrder[a.priority] ?? 0));
        break;
      case 'createdAt':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Todo List',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.filter_list_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              onSelected: (value) {
                setState(() {
                  _filter = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.list_rounded,
                        size: 20,
                        color: _filter == 'all' ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text('All'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: _filter == 'pending' ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Pending'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 20,
                        color: _filter == 'completed' ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Completed'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'overdue',
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        size: 20,
                        color: _filter == 'overdue' ? Colors.red : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Overdue'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.sort_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 20,
                ),
              ),
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'dueDate',
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 20,
                        color: _sortBy == 'dueDate' ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Due Date'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'priority',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: 20,
                        color: _sortBy == 'priority' ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Priority'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'createdAt',
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: _sortBy == 'createdAt' ? Theme.of(context).colorScheme.primary : null,
                      ),
                      const SizedBox(width: 12),
                      Text('Created Date'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_todos.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.task_alt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_filteredTodos.length} ${_filter == 'all' ? 'total' : _filter} todos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFilterDescription(),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_filter == 'overdue')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red[700],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Overdue',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          Expanded(
            child: _filteredTodos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getEmptyIcon(),
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _getEmptyMessage(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getEmptySubMessage(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _showTodoDialog(),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Todo'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTodos.length,
                    itemBuilder: (context, index) {
                      final todo = _filteredTodos[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _showTodoDialog(todo: todo),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: todo.isCompleted,
                          onChanged: (value) async {
                            final updatedTodo = todo.copyWith(isCompleted: value ?? false);
                            final success = await widget.storageService.updateTodo(updatedTodo);
                            if (success) {
                              setState(() {
                                final index = _todos.indexWhere((t) => t.id == todo.id);
                                if (index != -1) {
                                  _todos[index] = updatedTodo;
                                }
                              });
                            } else {
                              _showErrorSnackBar('Failed to update todo');
                            }
                          },
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          todo.title,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                            color: todo.isCompleted 
                                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                                : null,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (todo.description != null && todo.description!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            todo.description!,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: todo.isCompleted 
                                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4)
                                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (todo.priority != 'medium')
                                              _buildPriorityChip(todo.priority),
                                            if (todo.dueDate != null)
                                              _buildDueDateChip(todo),
                                            if (todo.category != null && todo.category!.isNotEmpty)
                                              _buildCategoryChip(todo.category!),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton(
                                    icon: Icon(
                                      Icons.more_vert_rounded,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, size: 20),
                                            SizedBox(width: 12),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                            SizedBox(width: 12),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showTodoDialog(todo: todo);
                                      } else if (value == 'delete') {
                                        _deleteTodo(todo);
                                      }
                                    },
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTodoDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Todo'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  String _getEmptyMessage() {
    switch (_filter) {
      case 'pending':
        return 'No pending todos';
      case 'completed':
        return 'No completed todos';
      case 'overdue':
        return 'No overdue todos';
      default:
        return 'No todos yet';
    }
  }

  String _getEmptySubMessage() {
    switch (_filter) {
      case 'pending':
        return 'Great! All your todos are completed';
      case 'completed':
        return 'Complete some todos to see them here';
      case 'overdue':
        return 'You\'re all caught up! No overdue todos';
      default:
        return 'Tap the + button to create your first todo';
    }
  }

  String _getFilterDescription() {
    switch (_filter) {
      case 'pending':
        return 'Tasks that need to be completed';
      case 'completed':
        return 'Tasks you\'ve finished';
      case 'overdue':
        return 'Tasks past their due date';
      default:
        return 'All your tasks and reminders';
    }
  }

  IconData _getEmptyIcon() {
    switch (_filter) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'completed':
        return Icons.check_circle_outline_rounded;
      case 'overdue':
        return Icons.warning_rounded;
      default:
        return Icons.task_alt_rounded;
    }
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flag_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateChip(Todo todo) {
    final isOverdue = _isOverdue(todo);
    final color = isOverdue ? Colors.red : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_rounded : Icons.calendar_today_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDueDate(todo.dueDate!),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_rounded,
            size: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isOverdue(Todo todo) {
    if (todo.isCompleted || todo.dueDate == null) return false;
    return todo.dueDate!.isBefore(DateTime.now());
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else {
      return '${(-difference.inDays)}d overdue';
    }
  }

  void _showTodoDialog({Todo? todo}) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descriptionController = TextEditingController(text: todo?.description ?? '');
    final categoryController = TextEditingController(text: todo?.category ?? '');
    String priority = todo?.priority ?? 'medium';
    DateTime? dueDate = todo?.dueDate;
    bool isEditing = todo != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_rounded : Icons.add_task_rounded,
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
                              isEditing ? 'Edit Todo' : 'Create Todo',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEditing 
                                  ? 'Update your task details'
                                  : 'Add a new task to your list',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Task Title',
                            hintText: 'What needs to be done?',
                            prefixIcon: const Icon(Icons.title_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Add more details about this task...',
                            prefixIcon: const Icon(Icons.description_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 3,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: categoryController,
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                  hintText: 'work, personal, shopping',
                                  prefixIcon: const Icon(Icons.label_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: priority,
                                decoration: InputDecoration(
                                  labelText: 'Priority',
                                  prefixIcon: const Icon(Icons.flag_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'low',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Low'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'medium',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.orange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Medium'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'high',
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('High'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setDialogState(() {
                                    priority = value ?? 'medium';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Due Date'),
                                    Text(
                                      dueDate != null 
                                          ? DateFormat('MMM d, yyyy').format(dueDate!) 
                                          : 'No due date set',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: dueDate != null 
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.outline,
                                        fontWeight: dueDate != null ? FontWeight.w600 : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (dueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setDialogState(() {
                                      dueDate = null;
                                    });
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today_rounded),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: dueDate ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      dueDate = date;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isNotEmpty) {
                              final newTodo = Todo(
                                id: todo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleController.text,
                                description: descriptionController.text.isEmpty ? null : descriptionController.text,
                                createdAt: todo?.createdAt ?? DateTime.now(),
                                dueDate: dueDate,
                                priority: priority,
                                category: categoryController.text.isEmpty ? null : categoryController.text,
                              );

                              bool success;
                              if (isEditing) {
                                success = await widget.storageService.updateTodo(newTodo);
                              } else {
                                success = await widget.storageService.addTodo(newTodo);
                              }

                              if (success) {
                                setState(() {
                                  if (isEditing) {
                                    final index = _todos.indexWhere((t) => t.id == newTodo.id);
                                    if (index != -1) {
                                      _todos[index] = newTodo;
                                    }
                                  } else {
                                    _todos.add(newTodo);
                                  }
                                });
                                Navigator.pop(context);
                              } else {
                                _showErrorSnackBar('Failed to ${isEditing ? 'update' : 'create'} todo');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(isEditing ? 'Update Todo' : 'Create Todo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteTodo(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.storageService.deleteTodo(todo.id);
              if (success) {
                setState(() {
                  _todos.removeWhere((t) => t.id == todo.id);
                });
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Failed to delete todo');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
