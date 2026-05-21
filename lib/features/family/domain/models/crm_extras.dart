// lib/features/family/domain/models/crm_extras.dart
//
// Local-only CRM extension record, keyed by contactId.
// The backend Contact model is UNCHANGED. All CRM-specific fields
// live here, serialised under prefs key `crm_extras_v1`.
//
// Stage values (canonical):
//   "prospect" | "discovery" | "proposal" | "negotiation" | "won" | "lost" | "none"
//
// "none" means the contact has not been added to any pipeline stage.
// "Active" = prospect | discovery | proposal | negotiation.

class CrmExtras {
  CrmExtras({
    required this.contactId,
    this.company,
    this.email,
    this.phone,
    this.dealStage = 'none',
    this.dealAmount,
    this.nextStep,
    this.nextStepDate,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  final String contactId;
  String? company;
  String? email;
  String? phone;
  String dealStage;
  double? dealAmount;
  String? nextStep;
  DateTime? nextStepDate;
  DateTime updatedAt;

  /// True for any stage that counts toward "active" pipeline.
  bool get isActive =>
      dealStage == 'prospect' ||
      dealStage == 'discovery' ||
      dealStage == 'proposal' ||
      dealStage == 'negotiation';

  static const _activeStages = {
    'prospect',
    'discovery',
    'proposal',
    'negotiation',
  };

  static bool stageIsActive(String stage) => _activeStages.contains(stage);

  // ── Serialisation ────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'contactId': contactId,
        'company': company,
        'email': email,
        'phone': phone,
        'dealStage': dealStage,
        'dealAmount': dealAmount,
        'nextStep': nextStep,
        'nextStepDate': nextStepDate?.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CrmExtras.fromJson(Map<String, dynamic> j) => CrmExtras(
        contactId: j['contactId'] as String,
        company: j['company'] as String?,
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        dealStage: (j['dealStage'] as String?) ?? 'none',
        dealAmount: (j['dealAmount'] as num?)?.toDouble(),
        nextStep: j['nextStep'] as String?,
        nextStepDate: j['nextStepDate'] != null
            ? DateTime.tryParse(j['nextStepDate'] as String)
            : null,
        updatedAt: j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String)
            : DateTime.now(),
      );

  CrmExtras copyWith({
    String? company,
    String? email,
    String? phone,
    String? dealStage,
    Object? dealAmount = _sentinel,
    String? nextStep,
    Object? nextStepDate = _sentinel,
    DateTime? updatedAt,
  }) =>
      CrmExtras(
        contactId: contactId,
        company: company ?? this.company,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        dealStage: dealStage ?? this.dealStage,
        dealAmount:
            dealAmount == _sentinel ? this.dealAmount : dealAmount as double?,
        nextStep: nextStep ?? this.nextStep,
        nextStepDate: nextStepDate == _sentinel
            ? this.nextStepDate
            : nextStepDate as DateTime?,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}

// Sentinel used so copyWith can distinguish "pass null" from "not passed".
const _sentinel = Object();
