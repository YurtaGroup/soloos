import 'package:flutter/foundation.dart';
import '../../domain/models/circle.dart';
import '../../../../services/api_service.dart';

class CirclesViewModel extends ChangeNotifier {
  List<Circle> _circles = [];
  bool _loading = false;
  String? _error;

  List<Circle> get circles => _circles;
  bool get loading => _loading;
  String? get error => _error;

  /// Check if a module is shared with anyone.
  bool isModuleShared(String module) {
    return _circles.any((c) => c.modules.contains(module) && c.members.length > 1);
  }

  /// Get all members for a given module (across all circles).
  List<CircleMember> getMembersForModule(String module) {
    final members = <String, CircleMember>{};
    for (final circle in _circles) {
      if (circle.modules.contains(module)) {
        for (final m in circle.members) {
          members[m.userId] = m;
        }
      }
    }
    return members.values.toList();
  }

  void reload() => loadCircles();

  Future<void> loadCircles() async {
    if (!ApiService.isAuthenticated) return;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await ApiService.getAll('circles');
      _circles = data.map((r) => Circle.fromJson(r)).toList();
    } catch (e) {
      _error = e.toString();
      _circles = [];
    }

    _loading = false;
    notifyListeners();
  }

  Future<Circle?> createCircle({
    required String name,
    String emoji = '',
    List<String> modules = const [],
  }) async {
    try {
      final data = await ApiService.insert('circles', {
        'name': name.trim(),
        'emoji': emoji,
        'modules': modules,
      });
      await loadCircles();
      return Circle.fromJson(data);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<String?> generateInvite(String circleId) async {
    try {
      final data = await _post('/api/circles/$circleId/invite');
      return data['code'] as String?;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> joinWithCode(String code) async {
    try {
      await _post('/api/circles/join', body: {'code': code.trim()});
      await loadCircles();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeMember(String circleId, String memberId) async {
    try {
      await _delete('/api/circles/$circleId/members/$memberId');
      await loadCircles();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCircle(String circleId) async {
    try {
      await _delete('/api/circles/$circleId');
      await loadCircles();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCircle(String circleId, {String? name, String? emoji, List<String>? modules}) async {
    try {
      await _patch('/api/circles/$circleId', body: {
        if (name != null) 'name': name,
        if (emoji != null) 'emoji': emoji,
        if (modules != null) 'modules': modules,
      });
      await loadCircles();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Direct HTTP helpers using ApiService internals
  static Future<dynamic> _post(String path, {Map<String, dynamic>? body}) async {
    return ApiService.directRequest('POST', path, body: body);
  }

  static Future<dynamic> _delete(String path) async {
    return ApiService.directRequest('DELETE', path);
  }

  static Future<dynamic> _patch(String path, {Map<String, dynamic>? body}) async {
    return ApiService.directRequest('PATCH', path, body: body);
  }
}
