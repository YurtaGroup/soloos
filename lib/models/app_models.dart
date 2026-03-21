import 'package:flutter/material.dart';

// ─── Task & Project ───────────────────────────────────────────────
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

class Task {
  final String id;
  String title;
  String notes;
  bool isDone;
  String priority; // high, medium, low
  DateTime? dueDate;
  DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.notes = '',
    this.isDone = false,
    this.priority = 'medium',
    this.dueDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'notes': notes,
        'isDone': isDone,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'],
        title: j['title'],
        notes: j['notes'] ?? '',
        isDone: j['isDone'] ?? false,
        priority: j['priority'] ?? 'medium',
        dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      );
}

// ─── Habits ───────────────────────────────────────────────────────
class Habit {
  final String id;
  String name;
  String emoji;
  String frequency; // daily, weekdays, weekends
  List<DateTime> completedDates;
  Color color;

  Habit({
    required this.id,
    required this.name,
    this.emoji = '✅',
    this.frequency = 'daily',
    List<DateTime>? completedDates,
    this.color = const Color(0xFF10B981),
  }) : completedDates = completedDates ?? [];

  bool isCompletedToday() {
    final today = DateTime.now();
    return completedDates.any(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    DateTime check = DateTime.now();
    for (var date in sorted) {
      if (date.year == check.year && date.month == check.month && date.day == check.day) {
        streak++;
        check = check.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'frequency': frequency,
        'completedDates': completedDates.map((d) => d.toIso8601String()).toList(),
        'color': color.value,
      };

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'] ?? '✅',
        frequency: j['frequency'] ?? 'daily',
        completedDates: (j['completedDates'] as List? ?? [])
            .map((d) => DateTime.parse(d))
            .toList(),
        color: Color(j['color'] ?? 0xFF10B981),
      );
}

// ─── Finance ──────────────────────────────────────────────────────
enum TransactionType { income, expense }

class Transaction {
  final String id;
  String title;
  double amount;
  TransactionType type;
  String category;
  DateTime date;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    this.category = 'Other',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'],
        title: j['title'],
        amount: (j['amount'] as num).toDouble(),
        type: j['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        category: j['category'] ?? 'Other',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
      );
}

// ─── Ideas ────────────────────────────────────────────────────────
enum IdeaStatus { active, archived, completed }

class Idea {
  final String id;
  String title;
  String description;
  IdeaStatus status;
  List<String> notes;
  DateTime createdAt;
  String? aiScript;

  Idea({
    required this.id,
    required this.title,
    this.description = '',
    this.status = IdeaStatus.active,
    List<String>? notes,
    DateTime? createdAt,
    this.aiScript,
  })  : notes = notes ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'aiScript': aiScript,
      };

  factory Idea.fromJson(Map<String, dynamic> j) => Idea(
        id: j['id'],
        title: j['title'],
        description: j['description'] ?? '',
        status: IdeaStatus.values.firstWhere(
          (e) => e.name == j['status'],
          orElse: () => IdeaStatus.active,
        ),
        notes: List<String>.from(j['notes'] ?? []),
        createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
        aiScript: j['aiScript'],
      );
}

// ─── Contacts ─────────────────────────────────────────────────────
class Contact {
  final String id;
  String name;
  String emoji;
  DateTime birthday;
  String relationship;
  String notes;

  Contact({
    required this.id,
    required this.name,
    this.emoji = '👤',
    required this.birthday,
    this.relationship = 'friend',
    this.notes = '',
  });

  int get daysUntilBirthday {
    final now = DateTime.now();
    final next = DateTime(now.year, birthday.month, birthday.day);
    final diff = next.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? diff + 365 : diff;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'birthday': birthday.toIso8601String(),
        'relationship': relationship,
        'notes': notes,
      };

  factory Contact.fromJson(Map<String, dynamic> j) => Contact(
        id: j['id'],
        name: j['name'],
        emoji: j['emoji'] ?? '👤',
        birthday: DateTime.parse(j['birthday']),
        relationship: j['relationship'] ?? 'friend',
        notes: j['notes'] ?? '',
      );
}

// ─── Standup Log ──────────────────────────────────────────────────
class StandupLog {
  final String id;
  DateTime date;
  String wins;
  String challenges;
  String priorities;
  String aiResponse;

  StandupLog({
    required this.id,
    DateTime? date,
    this.wins = '',
    this.challenges = '',
    this.priorities = '',
    this.aiResponse = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'wins': wins,
        'challenges': challenges,
        'priorities': priorities,
        'aiResponse': aiResponse,
      };

  factory StandupLog.fromJson(Map<String, dynamic> j) => StandupLog(
        id: j['id'],
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        wins: j['wins'] ?? '',
        challenges: j['challenges'] ?? '',
        priorities: j['priorities'] ?? '',
        aiResponse: j['aiResponse'] ?? '',
      );
}
