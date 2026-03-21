import 'dart:convert';
import '../../../../services/claude_service.dart';
import '../../domain/models/debt_item.dart';
import '../../domain/models/obligation_item.dart';
import '../../domain/models/parsed_finance_input.dart';

class FinanceAiParserService {
  final ClaudeService _claude;

  FinanceAiParserService({ClaudeService? claude})
      : _claude = claude ?? ClaudeService();

  static String get _system => '''
You are a personal finance parser. Extract structured data from natural language input.

Return ONLY valid JSON, no explanation.

For DEBT entries (user owes money):
{
  "type": "debt",
  "title": "string",
  "creditor_name": "string",
  "category": "friend|family|studentLoan|bankLoan|creditCard|other",
  "amount": number,
  "currency": "USD|KGS",
  "due_date": "YYYY-MM-DD or null",
  "monthly_payment_goal": number or null,
  "priority": "low|medium|high",
  "notes": "string or null",
  "confidence": {
    "title": 0.0-1.0,
    "creditor_name": 0.0-1.0,
    "category": 0.0-1.0,
    "amount": 0.0-1.0,
    "currency": 0.0-1.0,
    "due_date": 0.0-1.0,
    "priority": 0.0-1.0
  }
}

For OBLIGATION entries (recurring payment):
{
  "type": "obligation",
  "title": "string",
  "category": "rent|utilities|subscription|insurance|salary|taxes|loan|other",
  "amount": number,
  "currency": "USD|KGS",
  "frequency": "weekly|biweekly|monthly|quarterly|annual",
  "due_day_of_month": number or null,
  "notes": "string or null",
  "confidence": {
    "title": 0.0-1.0,
    "category": 0.0-1.0,
    "amount": 0.0-1.0,
    "currency": 0.0-1.0,
    "frequency": 0.0-1.0,
    "due_day_of_month": 0.0-1.0
  }
}

If unclear, return: { "type": "unknown" }

Rules:
- Treat "every month", "monthly", "/mo", "per month" as frequency: monthly
- Treat "I owe", "borrowed from", "I need to pay back" as debt
- Treat "I pay X for Y", "my X costs Y/month", "subscription" as obligation
- Default currency USD unless user says "som", "сом", "KGS"
- If due date is relative ("next month", "in 3 months"), compute from today: ''' +
      DateTime.now().toIso8601String().substring(0, 10) +
      '''
- Confidence 0.9+ = clear/explicit. 0.5-0.9 = inferred. Below 0.5 = guessed.
''';

  Future<ParsedFinanceInput> parse(String rawInput) async {
    final result = await _claude.callRaw(
      rawInput,
      systemPrompt: _system,
      maxTokens: 512,
    );

    try {
      final jsonStr = _extractJson(result);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _buildParsed(rawInput, data);
    } catch (_) {
      return ParsedFinanceInput.unknown(rawInput);
    }
  }

  String _extractJson(String text) {
    // Strip markdown code fences if present
    final cleaned = text.trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1) throw const FormatException('no JSON');
    return cleaned.substring(start, end + 1);
  }

  ParsedFinanceInput _buildParsed(
      String raw, Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'unknown';
    final conf = data['confidence'] as Map<String, dynamic>? ?? {};

    double c(String key, {double fallback = 0.5}) =>
        (conf[key] as num?)?.toDouble() ?? fallback;

    bool needsConf(String key, {double threshold = 0.75}) =>
        c(key) < threshold;

    if (type == 'debt') {
      final parsed = ParsedDebt(
        title: ParsedField(
          value: data['title'] as String? ?? 'Unnamed debt',
          confidence: c('title'),
          needsConfirmation: needsConf('title'),
        ),
        creditorName: ParsedField(
          value: data['creditor_name'] as String? ?? '',
          confidence: c('creditor_name'),
          needsConfirmation: needsConf('creditor_name'),
        ),
        category: ParsedField(
          value: _parseDebtCategory(data['category']),
          confidence: c('category'),
          needsConfirmation: needsConf('category'),
        ),
        amount: ParsedField(
          value: (data['amount'] as num?)?.toDouble() ?? 0.0,
          confidence: c('amount'),
          needsConfirmation: needsConf('amount') || (data['amount'] == null),
        ),
        currency: ParsedField(
          value: data['currency'] as String? ?? 'USD',
          confidence: c('currency'),
          needsConfirmation: needsConf('currency'),
        ),
        dueDate: ParsedField(
          value: _parseDate(data['due_date']),
          confidence: c('due_date'),
          needsConfirmation: data['due_date'] == null,
        ),
        monthlyPaymentGoal: ParsedField(
          value: (data['monthly_payment_goal'] as num?)?.toDouble(),
          confidence: 0.9,
        ),
        priority: ParsedField(
          value: _parseDebtPriority(data['priority']),
          confidence: c('priority'),
          needsConfirmation: needsConf('priority'),
        ),
        notes: data['notes'] as String?,
      );

      return ParsedFinanceInput(
        type: ParsedFinanceType.debt,
        debt: parsed,
        rawInput: raw,
        overallConfidence: _avgConfidence(conf),
        clarificationMessage: parsed.hasAmbiguity
            ? 'Please confirm: ${parsed.ambiguousFields.join(', ')}'
            : null,
      );
    }

    if (type == 'obligation') {
      final parsed = ParsedObligation(
        title: ParsedField(
          value: data['title'] as String? ?? 'Unnamed obligation',
          confidence: c('title'),
          needsConfirmation: needsConf('title'),
        ),
        category: ParsedField(
          value: _parseObligationCategory(data['category']),
          confidence: c('category'),
          needsConfirmation: needsConf('category'),
        ),
        amount: ParsedField(
          value: (data['amount'] as num?)?.toDouble() ?? 0.0,
          confidence: c('amount'),
          needsConfirmation: needsConf('amount') || (data['amount'] == null),
        ),
        currency: ParsedField(
          value: data['currency'] as String? ?? 'USD',
          confidence: c('currency'),
          needsConfirmation: needsConf('currency'),
        ),
        frequency: ParsedField(
          value: _parseFrequency(data['frequency']),
          confidence: c('frequency'),
          needsConfirmation: needsConf('frequency'),
        ),
        dueDayOfMonth: ParsedField(
          value: data['due_day_of_month'] as int?,
          confidence: c('due_day_of_month'),
          needsConfirmation: data['due_day_of_month'] == null,
        ),
        notes: data['notes'] as String?,
      );

      return ParsedFinanceInput(
        type: ParsedFinanceType.obligation,
        obligation: parsed,
        rawInput: raw,
        overallConfidence: _avgConfidence(conf),
        clarificationMessage: parsed.hasAmbiguity
            ? 'Please confirm: ${parsed.ambiguousFields.join(', ')}'
            : null,
      );
    }

    return ParsedFinanceInput.unknown(raw);
  }

  double _avgConfidence(Map<String, dynamic> conf) {
    if (conf.isEmpty) return 0.5;
    final values = conf.values.map((v) => (v as num).toDouble()).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }

  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    return DateTime.tryParse(val.toString());
  }

  DebtCategory _parseDebtCategory(dynamic val) {
    return DebtCategory.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => DebtCategory.other,
    );
  }

  DebtPriority _parseDebtPriority(dynamic val) {
    return DebtPriority.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => DebtPriority.medium,
    );
  }

  ObligationCategory _parseObligationCategory(dynamic val) {
    return ObligationCategory.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => ObligationCategory.other,
    );
  }

  ObligationFrequency _parseFrequency(dynamic val) {
    return ObligationFrequency.values.firstWhere(
      (e) => e.name == val?.toString(),
      orElse: () => ObligationFrequency.monthly,
    );
  }
}
