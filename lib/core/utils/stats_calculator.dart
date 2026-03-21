import '../../models/app_models.dart';

/// Encapsulates all cross-feature stat calculations used in the Dashboard.
/// Previously these were duplicated verbatim in both _refreshDigest() and
/// _HomeTab.build() inside dashboard_screen.dart.
class DashboardStats {
  const DashboardStats({
    required this.openTasks,
    required this.doneTasks,
    required this.habitStreak,
    required this.habitsToday,
    required this.totalHabits,
    required this.balance,
    required this.activeIdeas,
    required this.upcomingBirthdays,
  });

  final int openTasks;
  final int doneTasks;
  final int habitStreak;
  final int habitsToday;
  final int totalHabits;
  final double balance;
  final List<Idea> activeIdeas;

  /// Contacts whose birthday is within 7 days, sorted by proximity.
  final List<Contact> upcomingBirthdays;

  /// Birthday labels formatted for the AI digest prompt.
  List<String> get upcomingBirthdayLabels =>
      upcomingBirthdays.map((c) => '${c.name} (${c.daysUntilBirthday}d)').toList();
}

/// Pure utility — no state, no Flutter dependencies.
/// Call [calculate] whenever you need fresh stats from storage data.
class StatsCalculator {
  StatsCalculator._();

  static DashboardStats calculate({
    required List<Project> projects,
    required List<Habit> habits,
    required List<Transaction> transactions,
    required List<Idea> ideas,
    required List<Contact> contacts,
    int birthdayWindowDays = 7,
  }) {
    final openTasks = projects.fold<int>(
      0,
      (sum, p) => sum + p.tasks.where((t) => !t.isDone).length,
    );
    final doneTasks = projects.fold<int>(
      0,
      (sum, p) => sum + p.tasks.where((t) => t.isDone).length,
    );
    final habitStreak = habits.isEmpty
        ? 0
        : habits.map((h) => h.currentStreak).reduce((a, b) => a > b ? a : b);
    final habitsToday = habits.where((h) => h.isCompletedToday()).length;
    final balance = transactions.fold<double>(
      0,
      (s, t) => t.type == TransactionType.income ? s + t.amount : s - t.amount,
    );
    final activeIdeas = ideas.where((i) => i.status == IdeaStatus.active).toList();
    final upcomingBirthdays = contacts
        .where((c) => c.daysUntilBirthday <= birthdayWindowDays)
        .toList()
      ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));

    return DashboardStats(
      openTasks: openTasks,
      doneTasks: doneTasks,
      habitStreak: habitStreak,
      habitsToday: habitsToday,
      totalHabits: habits.length,
      balance: balance,
      activeIdeas: activeIdeas,
      upcomingBirthdays: upcomingBirthdays,
    );
  }
}
