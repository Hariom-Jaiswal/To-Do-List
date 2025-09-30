import 'package:flutter/material.dart';

class LoadingService {
  static final LoadingService _instance = LoadingService._internal();
  factory LoadingService() => _instance;
  LoadingService._internal();

  bool _isLoading = false;
  String _loadingMessage = 'Loading...';
  final List<VoidCallback> _listeners = [];

  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  void showLoading(String message) {
    _isLoading = true;
    _loadingMessage = message;
    _notifyListeners();
  }

  void hideLoading() {
    _isLoading = false;
    _loadingMessage = 'Loading...';
    _notifyListeners();
  }

  Future<T> withLoading<T>(
    Future<T> Function() operation, {
    String? message,
  }) async {
    showLoading(message ?? 'Loading...');
    try {
      final result = await operation();
      hideLoading();
      return result;
    } catch (e) {
      hideLoading();
      rethrow;
    }
  }
}
