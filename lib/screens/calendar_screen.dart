import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../services/storage_service.dart';

class CalendarScreen extends StatefulWidget {
  final StorageService storageService;
  
  const CalendarScreen({super.key, required this.storageService});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier<List<CalendarEvent>>([]);
    _loadEvents();
    
    // Listen to data changes for both events and todos
    widget.storageService.addEventsListener(_loadEvents);
    widget.storageService.addTodosListener(_loadEvents);
  }

  @override
  void dispose() {
    widget.storageService.removeEventsListener(_loadEvents);
    widget.storageService.removeTodosListener(_loadEvents);
    _selectedEvents.dispose();
    super.dispose();
  }

  void _loadEvents() async {
    await widget.storageService.initializeData();
    if (mounted) {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final events = widget.storageService.getEventsForDay(day);
    final todos = widget.storageService.getAllTodos();
    
    // Convert todos with due dates to calendar events
    final todoEvents = todos
        .where((todo) => todo.dueDate != null && 
            todo.dueDate!.year == day.year &&
            todo.dueDate!.month == day.month &&
            todo.dueDate!.day == day.day)
        .map((todo) => CalendarEvent(
          id: 'todo_${todo.id}',
          title: todo.title,
          description: todo.description,
          date: todo.dueDate!,
          color: _getTodoPriorityColor(todo.priority),
          isAllDay: true,
        ))
        .toList();
    
    return [...events, ...todoEvents];
  }

  String _getTodoPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return '#EF4444'; // Red
      case 'medium':
        return '#F59E0B'; // Orange
      case 'low':
        return '#10B981'; // Green
      default:
        return '#6366F1'; // Primary color
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => _showAddEventDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markersMaxCount: 4,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                markerSize: 6,
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                weekendDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                holidayDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                outsideDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                disabledDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                cellMargin: const EdgeInsets.all(4),
                cellPadding: const EdgeInsets.all(0),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ) ?? const TextStyle(fontWeight: FontWeight.w700),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                headerPadding: const EdgeInsets.symmetric(vertical: 16),
                leftChevronPadding: const EdgeInsets.only(left: 16),
                rightChevronPadding: const EdgeInsets.only(right: 16),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ) ?? TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                weekendStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ) ?? TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              onDaySelected: _onDaySelected,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                if (value.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events for this day',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to add an event',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showEditEventDialog(event),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: event.color != null
                                        ? Color(int.parse(event.color!.substring(1, 7), radix: 16) + 0xFF000000)
                                        : Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (event.id.startsWith('todo_')) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'TODO',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Expanded(
                                            child: Text(
                                              event.title,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (event.description != null && event.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          event.description!,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (event.startTime != null) ...[
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('HH:mm').format(event.startTime!),
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ] else if (event.id.startsWith('todo_')) ...[
                                            Icon(
                                              Icons.task_alt_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'All Day',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                          if (event.location != null && event.location!.isNotEmpty) ...[
                                            if (event.startTime != null || event.id.startsWith('todo_')) const SizedBox(width: 16),
                                            Icon(
                                              Icons.location_on_rounded,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.outline,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                event.location!,
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.outline,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
                                    if (event.id.startsWith('todo_'))
                                      const PopupMenuItem(
                                        value: 'view_todo',
                                        child: Row(
                                          children: [
                                            Icon(Icons.task_alt_rounded, size: 20),
                                            SizedBox(width: 12),
                                            Text('View Todo'),
                                          ],
                                        ),
                                      )
                                    else ...[
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
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showEditEventDialog(event);
                                    } else if (value == 'delete') {
                                      _deleteEvent(event);
                                    } else if (value == 'view_todo') {
                                      _showTodoInfo(event);
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    _showEventDialog();
  }

  void _showEditEventDialog(CalendarEvent event) {
    _showEventDialog(event: event);
  }

  void _showEventDialog({CalendarEvent? event}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    DateTime selectedDate = event?.date ?? _selectedDay ?? DateTime.now();
    TimeOfDay? startTime = event?.startTime != null 
        ? TimeOfDay.fromDateTime(event!.startTime!) 
        : null;
    TimeOfDay? endTime = event?.endTime != null 
        ? TimeOfDay.fromDateTime(event!.endTime!) 
        : null;
    bool isAllDay = event?.isAllDay ?? false;
    String selectedColor = event?.color ?? '#6366F1';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
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
                          event == null ? Icons.add_rounded : Icons.edit_rounded,
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
                              event == null ? 'Add Event' : 'Edit Event',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event == null 
                                  ? 'Create a new calendar event'
                                  : 'Update your event details',
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Event Title',
                            hintText: 'Enter event title',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Add event description (optional)',
                            prefixIcon: Icon(Icons.description_rounded),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Add event location (optional)',
                            prefixIcon: Icon(Icons.location_on_rounded),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  Icons.calendar_today_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                title: const Text('Date'),
                                subtitle: Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded),
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    setDialogState(() {
                                      selectedDate = date;
                                    });
                                  }
                                },
                              ),
                              const Divider(height: 1),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('All Day Event'),
                                subtitle: const Text('Event lasts the entire day'),
                                value: isAllDay,
                                onChanged: (value) {
                                  setDialogState(() {
                                    isAllDay = value ?? false;
                                  });
                                },
                              ),
                              if (!isAllDay) ...[
                                const Divider(height: 1),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.access_time_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  title: const Text('Start Time'),
                                  subtitle: Text(
                                    startTime != null 
                                        ? startTime!.format(context) 
                                        : 'Select start time',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: startTime != null ? FontWeight.w500 : null,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: startTime ?? TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        startTime = time;
                                      });
                                    }
                                  },
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.access_time_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  title: const Text('End Time'),
                                  subtitle: Text(
                                    endTime != null 
                                        ? endTime!.format(context) 
                                        : 'Select end time',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: endTime != null ? FontWeight.w500 : null,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded),
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: endTime ?? TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        endTime = time;
                                      });
                                    }
                                  },
                                ),
                              ],
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
                              final newEvent = CalendarEvent(
                                id: event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleController.text,
                                description: descriptionController.text.isEmpty ? null : descriptionController.text,
                                date: selectedDate,
                                startTime: isAllDay ? null : (startTime != null 
                                    ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 
                                              startTime!.hour, startTime!.minute) 
                                    : null),
                                endTime: isAllDay ? null : (endTime != null 
                                    ? DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 
                                              endTime!.hour, endTime!.minute) 
                                    : null),
                                isAllDay: isAllDay,
                                location: locationController.text.isEmpty ? null : locationController.text,
                                color: selectedColor,
                              );

                              bool success;
                              if (event == null) {
                                success = await widget.storageService.addEvent(newEvent);
                              } else {
                                success = await widget.storageService.updateEvent(newEvent);
                              }

                              if (success) {
                                setState(() {
                                  _selectedEvents.value = _getEventsForDay(_selectedDay!);
                                });
                                Navigator.pop(context);
                              } else {
                                _showErrorSnackBar('Failed to ${event == null ? 'create' : 'update'} event');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(event == null ? 'Add Event' : 'Update Event'),
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

  void _deleteEvent(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await widget.storageService.deleteEvent(event.id);
              if (success) {
                setState(() {
                  _selectedEvents.value = _getEventsForDay(_selectedDay!);
                });
                Navigator.pop(context);
              } else {
                _showErrorSnackBar('Failed to delete event');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTodoInfo(CalendarEvent event) {
    // Extract todo ID from event ID
    final todoId = event.id.replaceFirst('todo_', '');
    final todos = widget.storageService.getAllTodos();
    final todo = todos.firstWhere((t) => t.id == todoId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.task_alt_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Todo Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todo.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (todo.description != null && todo.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                todo.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  size: 16,
                  color: _getPriorityColor(todo.priority),
                ),
                const SizedBox(width: 8),
                Text(
                  'Priority: ${todo.priority.toUpperCase()}',
                  style: TextStyle(
                    color: _getPriorityColor(todo.priority),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Due: ${DateFormat('MMM d, yyyy').format(todo.dueDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (todo.category != null && todo.category!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.label_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Category: ${todo.category}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  todo.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: todo.isCompleted ? Colors.green : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  todo.isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(
                    color: todo.isCompleted ? Colors.green : Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
        return Theme.of(context).colorScheme.primary;
    }
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
