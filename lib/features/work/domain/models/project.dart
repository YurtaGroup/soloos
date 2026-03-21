import 'package:flutter/material.dart';
import 'task.dart';

class Project {
  final String id;
  String name;
  String description;
  List<Task> tasks;
  Color color;
  DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    this.description = '',
    List<Task>? tasks,
    this.color = const Color(0xFF3B82F6),
    DateTime? createdAt,
  })  : tasks = tasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  int get completedTasks => tasks.where((t) => t.isDone).length;
  double get progress => tasks.isEmpty ? 0 : completedTasks / tasks.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'color': color.value,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> j) => Project(
        id: j['id'],
        name: j['name'],
        description: j['description'] ?? '',
        tasks: (j['tasks'] as List? ?? []).map((t) => Task.fromJson(t)).toList(),
        color: Color(j['color'] ?? 0xFF3B82F6),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}
