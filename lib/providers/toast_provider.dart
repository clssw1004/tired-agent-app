import 'package:flutter/foundation.dart';

enum ToastType { info, success, error }

class ToastItem {
  final String id;
  final String message;
  final ToastType type;
  ToastItem({required this.id, required this.message, required this.type});
}

class ToastProvider extends ChangeNotifier {
  final List<ToastItem> _toasts = [];
  static const int _maxToasts = 5;

  List<ToastItem> get toasts => List.unmodifiable(_toasts);

  void _add(String message, ToastType type) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _toasts.add(ToastItem(id: id, message: message, type: type));
    if (_toasts.length > _maxToasts) _toasts.removeAt(0);
    notifyListeners();
    Future.delayed(const Duration(seconds: 4), () => dismiss(id));
  }

  void show(String message) => _add(message, ToastType.info);
  void success(String message) => _add(message, ToastType.success);
  void error(String message) => _add(message, ToastType.error);

  void dismiss(String id) {
    _toasts.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
