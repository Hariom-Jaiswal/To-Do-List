import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../models/note.dart';
import '../models/calendar_event.dart';

class StorageService {
  static const String _todosKey = 'todos';
  static const String _notesKey = 'notes';
  static const String _eventsKey = 'events';

  // Cache for in-memory storage
  List<Todo> _todos = [];
  List<Note> _notes = [];
  List<CalendarEvent> _events = [];
  bool _initialized = false;
  bool _isLoading = false;
  String? _lastError;

  // Listeners for data changes
  final List<VoidCallback> _todosListeners = [];
  final List<VoidCallback> _notesListeners = [];
  final List<VoidCallback> _eventsListeners = [];

  // Initialize data
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _loadData();
      _initialized = true;
    }
  }

  Future<void> _loadData() async {
    try {
      _isLoading = true;
      _lastError = null;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Load todos
      final todosJson = prefs.getString(_todosKey);
      if (todosJson != null) {
        final List<dynamic> todosList = jsonDecode(todosJson);
        _todos = todosList.map((json) => Todo.fromJson(json)).toList();
      }

      // Load notes
      final notesJson = prefs.getString(_notesKey);
      if (notesJson != null) {
        final List<dynamic> notesList = jsonDecode(notesJson);
        _notes = notesList.map((json) => Note.fromJson(json)).toList();
      }

      // Load events
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final List<dynamic> eventsList = jsonDecode(eventsJson);
        _events = eventsList.map((json) => CalendarEvent.fromJson(json)).toList();
      }
    } catch (e) {
      _lastError = 'Failed to load data: $e';
      // Initialize with empty lists on error
      _todos = [];
      _notes = [];
      _events = [];
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _saveData() async {
    try {
      _lastError = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_todosKey, jsonEncode(_todos.map((t) => t.toJson()).toList()));
      await prefs.setString(_notesKey, jsonEncode(_notes.map((n) => n.toJson()).toList()));
      await prefs.setString(_eventsKey, jsonEncode(_events.map((e) => e.toJson()).toList()));
    } catch (e) {
      _lastError = 'Failed to save data: $e';
      rethrow;
    }
  }

  // Getters for loading state and errors
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  // Todo methods
  Future<bool> addTodo(Todo todo) async {
    try {
      await _ensureInitialized();
      _todos.add(todo);
      await _saveData();
      _notifyTodosListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to add todo: $e';
      return false;
    }
  }

  List<Todo> getAllTodos() {
    return List.from(_todos);
  }

  Future<bool> updateTodo(Todo todo) async {
    try {
      await _ensureInitialized();
      final index = _todos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        _todos[index] = todo;
        await _saveData();
        _notifyTodosListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to update todo: $e';
      return false;
    }
  }

  Future<bool> deleteTodo(String id) async {
    try {
      await _ensureInitialized();
      _todos.removeWhere((t) => t.id == id);
      await _saveData();
      _notifyTodosListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to delete todo: $e';
      return false;
    }
  }

  // Note methods
  Future<bool> addNote(Note note) async {
    try {
      await _ensureInitialized();
      _notes.add(note);
      await _saveData();
      _notifyNotesListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to add note: $e';
      return false;
    }
  }

  List<Note> getAllNotes() {
    return List.from(_notes);
  }

  Future<bool> updateNote(Note note) async {
    try {
      await _ensureInitialized();
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        await _saveData();
        _notifyNotesListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to update note: $e';
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      await _ensureInitialized();
      _notes.removeWhere((n) => n.id == id);
      await _saveData();
      _notifyNotesListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to delete note: $e';
      return false;
    }
  }

  // Calendar Event methods
  Future<bool> addEvent(CalendarEvent event) async {
    try {
      await _ensureInitialized();
      _events.add(event);
      await _saveData();
      _notifyEventsListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to add event: $e';
      return false;
    }
  }

  List<CalendarEvent> getAllEvents() {
    return List.from(_events);
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.date.year == day.year &&
             event.date.month == day.month &&
             event.date.day == day.day;
    }).toList();
  }

  Future<bool> updateEvent(CalendarEvent event) async {
    try {
      await _ensureInitialized();
      final index = _events.indexWhere((e) => e.id == event.id);
      if (index != -1) {
        _events[index] = event;
        await _saveData();
        _notifyEventsListeners();
        return true;
      }
      return false;
    } catch (e) {
      _lastError = 'Failed to update event: $e';
      return false;
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _ensureInitialized();
      _events.removeWhere((e) => e.id == id);
      await _saveData();
      _notifyEventsListeners();
      return true;
    } catch (e) {
      _lastError = 'Failed to delete event: $e';
      return false;
    }
  }

  // Initialize data on app start
  Future<void> initializeData() async {
    await _ensureInitialized();
  }

  // Listener management
  void addTodosListener(VoidCallback listener) {
    _todosListeners.add(listener);
  }

  void removeTodosListener(VoidCallback listener) {
    _todosListeners.remove(listener);
  }

  void addNotesListener(VoidCallback listener) {
    _notesListeners.add(listener);
  }

  void removeNotesListener(VoidCallback listener) {
    _notesListeners.remove(listener);
  }

  void addEventsListener(VoidCallback listener) {
    _eventsListeners.add(listener);
  }

  void removeEventsListener(VoidCallback listener) {
    _eventsListeners.remove(listener);
  }

  // Notify listeners
  void _notifyTodosListeners() {
    for (final listener in _todosListeners) {
      listener();
    }
  }

  void _notifyNotesListeners() {
    for (final listener in _notesListeners) {
      listener();
    }
  }

  void _notifyEventsListeners() {
    for (final listener in _eventsListeners) {
      listener();
    }
  }

  // Refresh data from storage
  Future<void> refreshData() async {
    await _loadData();
    _notifyTodosListeners();
    _notifyNotesListeners();
    _notifyEventsListeners();
  }

  // Get statistics
  Map<String, int> getStatistics() {
    final now = DateTime.now();
    final overdueTodos = _todos.where((todo) => 
        !todo.isCompleted && 
        todo.dueDate != null && 
        todo.dueDate!.isBefore(now)).length;
    
    final completedTodos = _todos.where((todo) => todo.isCompleted).length;
    final pendingTodos = _todos.where((todo) => !todo.isCompleted).length;
    
    final todayEvents = _events.where((event) {
      return event.date.year == now.year &&
             event.date.month == now.month &&
             event.date.day == now.day;
    }).length;

    return {
      'totalTodos': _todos.length,
      'completedTodos': completedTodos,
      'pendingTodos': pendingTodos,
      'overdueTodos': overdueTodos,
      'totalNotes': _notes.length,
      'totalEvents': _events.length,
      'todayEvents': todayEvents,
    };
  }
}
