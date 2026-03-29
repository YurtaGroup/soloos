import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'pro_service.dart';

class ClaudeService {
  // Singleton
  static final ClaudeService _instance = ClaudeService._internal();
  factory ClaudeService() => _instance;
  ClaudeService._internal();

  static const String _directUrl = 'https://api.anthropic.com/v1/messages';
  static const String _model = 'claude-sonnet-4-20250514';
  static const String _version = '2023-06-01';

  /// Set this to your Vercel deployment URL (e.g. https://solo-os.vercel.app)
  static String proxyBaseUrl = 'https://solo-os.vercel.app';

  final StorageService _storage = StorageService();
  final ProService _pro = ProService();

  String get _apiKey => _storage.apiKey;
  bool get _useProxy => _apiKey.isEmpty;

  /// Check if the user can make an AI call (respects free tier limit).
  /// Returns null if allowed, or an error message string if blocked.
  Future<String?> checkAiLimit() async {
    if (_pro.hasAccess) return null; // Pro or trial — no limit
    final canCall = await _pro.canMakeAiCall();
    if (canCall) return null;
    final used = await _pro.aiCallsUsedToday();
    return 'limit:$used:${ProService.freeAiCallsPerDay}';
  }

  // ─── Core call ────────────────────────────────────────────────

  /// Public raw call — for feature services that need direct access
  Future<String> callRaw(
    String userMessage, {
    String? systemPrompt,
    int maxTokens = 1024,
  }) =>
      _call(userMessage, systemPrompt: systemPrompt, maxTokens: maxTokens);

  Future<String> _call(
    String userMessage, {
    String? systemPrompt,
    int maxTokens = 1024,
  }) async {
    try {
      String result;
      if (_useProxy) {
        result = await _callProxy(userMessage, systemPrompt: systemPrompt, maxTokens: maxTokens);
      } else {
        result = await _callDirect(userMessage, systemPrompt: systemPrompt, maxTokens: maxTokens);
      }
      // Track usage for free-tier limiting
      await _pro.recordAiCall();
      return result;
    } on TimeoutException {
      return '❌ Request timed out. Check your connection.';
    } catch (e) {
      return '❌ Network error: $e';
    }
  }

  /// Call via your Vercel proxy (no API key needed on client)
  Future<String> _callProxy(
    String userMessage, {
    String? systemPrompt,
    int maxTokens = 1024,
  }) async {
    final response = await http.post(
      Uri.parse('$proxyBaseUrl/api/claude'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
        if (systemPrompt != null) 'system': systemPrompt,
        'max_tokens': maxTokens,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'] as String;
    } else if (response.statusCode == 429) {
      return '⚠️ Daily AI limit reached. Add your own API key in Settings for unlimited access.';
    } else {
      return '❌ AI service unavailable. Try again later.';
    }
  }

  /// Call Anthropic API directly (user has their own key)
  Future<String> _callDirect(
    String userMessage, {
    String? systemPrompt,
    int maxTokens = 1024,
  }) async {
    final response = await http.post(
      Uri.parse(_directUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': _version,
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': maxTokens,
        if (systemPrompt != null) 'system': systemPrompt,
        'messages': [
          {'role': 'user', 'content': userMessage},
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'] as String;
    } else {
      final err = jsonDecode(response.body);
      return '❌ Error ${response.statusCode}: ${err['error']?['message'] ?? response.body}';
    }
  }

  // ─── Onboarding Setup ─────────────────────────────────────────
  /// Generate personalized project tasks, habit, and first digest from onboarding answers.
  /// Returns JSON with: project_tasks (list of strings), habit_emoji, digest (string).
  Future<String> generateOnboardingSetup({
    required String userName,
    required String business,
    required String challenge,
    required String habit,
  }) async {
    const system = '''You are Solo OS, an AI operating system for solopreneurs.
The user just installed the app and told you about their business, challenge, and a habit they want.
Generate personalized data to populate their workspace. Return ONLY valid JSON, no markdown.''';

    final prompt = '''
User: $userName
Business: $business
Biggest challenge this week: $challenge
Habit they want to nail: $habit

Return this exact JSON structure:
{
  "project_name": "their business name, short",
  "project_tasks": ["task 1", "task 2", "task 3", "task 4"],
  "task_priorities": ["high", "high", "medium", "medium"],
  "habit_name": "concise habit name based on their answer",
  "habit_emoji": "one emoji that fits",
  "digest": "A personalized 4-5 sentence morning briefing addressing them by name, referencing their business, challenge, and habit. Be energizing and specific. Use emoji headers."
}

Tasks should be real, actionable next steps for their specific business.
Make the digest feel like a brilliant chief of staff who already knows them.
''';

    return _call(prompt, systemPrompt: system, maxTokens: 600);
  }

  // ─── Daily AI Digest ──────────────────────────────────────────
  Future<String> generateDailyDigest({
    required String userName,
    required int openTasks,
    required int completedTasks,
    required int habitStreak,
    required int habitsToday,
    required int totalHabits,
    required double balance,
    required List<String> activeIdeas,
    required List<String> upcomingBirthdays,
  }) async {
    const system = '''You are Solo OS — an AI executive assistant for a solopreneur.
Your job: give a sharp, high-energy daily briefing. Be concise, actionable, motivating.
Format with emoji headers. Max 5 bullet points per section. Focus on the 20% actions that create 80% results.
Speak directly to the user. Be like a brilliant chief of staff.''';

    final prompt = '''
Good morning $userName! Generate today's AI digest based on this data:

📋 WORK:
- Open tasks: $openTasks
- Completed: $completedTasks
- Active ideas: ${activeIdeas.join(', ')}

💪 HEALTH:
- Habit streak: $habitStreak days
- Today's habits: $habitsToday/$totalHabits completed

💰 FINANCE:
- Current balance: \$${balance.toStringAsFixed(0)}

🎂 UPCOMING BIRTHDAYS: ${upcomingBirthdays.isEmpty ? 'None this week' : upcomingBirthdays.join(', ')}

Generate:
1. 🎯 Today's Top 3 Focus (Pareto priorities)
2. ⚡ Quick Wins (under 5 minutes)
3. 💡 AI Insight of the day
4. 📊 Performance snapshot
Keep it punchy and energizing. Under 200 words total.
''';

    return _call(prompt, systemPrompt: system, maxTokens: 600);
  }

  // ─── Standup Analysis ─────────────────────────────────────────
  Future<String> analyzeStandup({
    required String wins,
    required String challenges,
    required String priorities,
  }) async {
    const system = '''You are an AI executive coach for a solopreneur.
Analyze their daily standup and provide: patterns, risks, opportunities, and a clear action recommendation.
Be direct, insightful, and brief. No fluff.''';

    final prompt = '''
Daily Standup Analysis:

✅ WINS: $wins
🚧 CHALLENGES: $challenges
🎯 PRIORITIES: $priorities

Provide:
1. 🔍 Pattern Recognition (what you notice)
2. ⚠️ Risk Alert (if any)
3. 💡 Opportunity Spotted
4. ✅ Tomorrow's Single Most Important Action

Keep under 150 words. Be brutally honest and helpful.
''';

    return _call(prompt, systemPrompt: system, maxTokens: 500);
  }

  // ─── Idea Validator ───────────────────────────────────────────
  Future<String> validateIdea(String ideaTitle, String description) async {
    const system = '''You are a serial entrepreneur and business analyst.
Validate ideas with the 80/20 rule. Focus on ROI, effort, and market fit.
Be honest — kill bad ideas fast, amplify good ones.''';

    final prompt = '''
Validate this business idea:

IDEA: $ideaTitle
DESCRIPTION: $description

Give me:
1. 📊 Viability Score (1-10)
2. ✅ 3 Strengths
3. ⚠️ 3 Risks
4. 💰 Revenue potential (rough)
5. ⚡ MVP in 30 days (yes/no + what it would be)
6. 🎯 Verdict: PURSUE / PARK / KILL

Be concise. Under 200 words.
''';

    return _call(prompt, systemPrompt: system, maxTokens: 600);
  }

  // ─── Script Writer ────────────────────────────────────────────
  Future<String> writeContentScript({
    required String topic,
    required String platform, // YouTube, Twitter, LinkedIn, etc.
    required String angle,
  }) async {
    const system = '''You are a viral content strategist and script writer.
You create hooks that stop scrollers and scripts that build authority.
Write for solopreneurs sharing their journey and expertise.''';

    final prompt = '''
Write a $platform script/post:

TOPIC: $topic
ANGLE: $angle

Deliver:
1. 🎣 HOOK (first 3 seconds/lines — must stop the scroll)
2. 📝 BODY (core content, 3 key points)
3. 🔥 CTA (clear next action)

For YouTube: include timestamps outline
For Twitter/X: thread format (5-7 tweets)
For LinkedIn: professional story format

Make it authentic and value-packed.
''';

    return _call(prompt, systemPrompt: system, maxTokens: 800);
  }

  // ─── Weekly Review ────────────────────────────────────────────
  Future<String> generateWeeklyReview({
    required int tasksCompleted,
    required int habitsCompleted,
    required double revenue,
    required double expenses,
    required List<String> wins,
    required List<String> lessons,
  }) async {
    const system = '''You are a strategic advisor for a solopreneur.
Generate a weekly performance review that drives growth.
Focus on trends, leverage points, and next week's strategy.''';

    final prompt = '''
Weekly Review Data:

📋 PRODUCTIVITY:
- Tasks completed: $tasksCompleted

💪 HEALTH:
- Habits completed: $habitsCompleted

💰 FINANCE:
- Revenue: \$${revenue.toStringAsFixed(0)}
- Expenses: \$${expenses.toStringAsFixed(0)}
- Net: \$${(revenue - expenses).toStringAsFixed(0)}

🏆 WINS: ${wins.join(', ')}
📚 LESSONS: ${lessons.join(', ')}

Generate:
1. 📈 Week Score (out of 10) with breakdown
2. 🔑 Key Leverage Point discovered
3. 🚀 3 Goals for next week
4. 💡 Strategic insight

Under 200 words. Be direct and inspiring.
''';

    return _call(prompt, systemPrompt: system, maxTokens: 600);
  }

  // ─── Chat ─────────────────────────────────────────────────────
  Future<String> chat(String message) async {
    const system = '''You are Solo OS, the AI executive assistant for a solopreneur.
You help with strategy, content, productivity, and business decisions.
You know the 80/20 Pareto principle deeply. Keep answers actionable and concise.''';

    return _call(message, systemPrompt: system, maxTokens: 1000);
  }
}
