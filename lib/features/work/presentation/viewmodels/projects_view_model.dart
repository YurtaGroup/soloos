import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/project.dart';
import '../../domain/models/task.dart';
import '../../../../services/storage_service.dart';
import '../../../gamification/data/services/gamification_event_bus.dart';
import '../../../gamification/domain/models/gamification_event.dart';

class ProjectsViewModel extends ChangeNotifier {
  ProjectsViewModel({StorageService? storage})
      : _storage = storage ?? StorageService() {
    _loadProjects();
  }

  final StorageService _storage;
  List<Project> _projects = [];

  List<Project> get projects => _projects;

  void _loadProjects() {
    _projects = _storage.getProjects();
    notifyListeners();
  }

  void reload() => _loadProjects();

  Future<bool> addProject({required String name, String description = ''}) async {
    if (name.trim().isEmpty) return false;
    final p = Project(
      id: const Uuid().v4(),
      name: name.trim(),
      description: description.trim(),
    );
    final projects = _storage.getProjects()..add(p);
    await _storage.saveProjects(projects);
    _loadProjects();
    return true;
  }

  Future<void> deleteProject(int index) async {
    _projects.removeAt(index);
    await _storage.saveProjects(_projects);
    _loadProjects();
  }

  Future<void> saveProjects() async {
    await _storage.saveProjects(_projects);
    _loadProjects();
  }

  void addTask(Project project, {required String title, required String priority}) {
    project.tasks.add(Task(
      id: const Uuid().v4(),
      title: title.trim(),
      priority: priority,
    ));
    _saveAndNotify();
  }

  void toggleTask(Task task) {
    final completing = !task.isDone;
    task.isDone = completing;
    if (completing) {
      GamificationEventBus.emit(
        GamificationEventType.taskCompleted,
        description: task.title,
      );
    }
    _saveAndNotify();
  }

  void deleteTask(Project project, Task task) {
    project.tasks.remove(task);
    _saveAndNotify();
  }

  Future<void> _saveAndNotify() async {
    await _storage.saveProjects(_projects);
    notifyListeners();
  }
}
