import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/models/family_person.dart';
import '../viewmodels/family_viewmodel.dart';

class AddEditFamilyPersonScreen extends StatefulWidget {
  final FamilyPerson? existing;
  const AddEditFamilyPersonScreen({super.key, this.existing});

  @override
  State<AddEditFamilyPersonScreen> createState() =>
      _AddEditFamilyPersonScreenState();
}

class _AddEditFamilyPersonScreenState
    extends State<AddEditFamilyPersonScreen> {
  final _nameCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  RelationshipType _relationship = RelationshipType.friend;
  PriorityLevel _priority = PriorityLevel.medium;
  DateTime? _birthday;
  int? _frequencyDays;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.existing!;
      _nameCtrl.text = p.fullName;
      _nicknameCtrl.text = p.nickname ?? '';
      _phoneCtrl.text = p.phone ?? '';
      _notesCtrl.text = p.notesSummary;
      _relationship = p.relationshipType;
      _priority = p.priorityLevel;
      _birthday = p.birthday;
      _frequencyDays = p.contactFrequencyGoalDays;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Person' : 'Add Person'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Name *', _nameCtrl, hint: 'Full name'),
            _field('Nickname', _nicknameCtrl, hint: 'Optional'),
            _field('Phone', _phoneCtrl,
                hint: 'Optional',
                keyboard: TextInputType.phone),
            _field('Notes', _notesCtrl,
                hint: 'What should you remember about them?', maxLines: 3),
            const SizedBox(height: 16),
            _label('Relationship'),
            _RelationshipPicker(
              selected: _relationship,
              onChanged: (v) => setState(() => _relationship = v),
            ),
            const SizedBox(height: 16),
            _label('Priority'),
            _PriorityPicker(
              selected: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 16),
            _label('Birthday'),
            _DateRow(
              date: _birthday,
              hint: 'Set birthday',
              onPick: (dt) => setState(() => _birthday = dt),
              onClear: () => setState(() => _birthday = null),
            ),
            const SizedBox(height: 16),
            _label('Contact frequency goal'),
            _FrequencyPicker(
              days: _frequencyDays,
              onChanged: (v) => setState(() => _frequencyDays = v),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint,
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')));
      return;
    }

    final vm = context.read<FamilyViewModel>();

    if (_isEditing) {
      final person = widget.existing!;
      person.notesSummary = _notesCtrl.text;
      person.priorityLevel = _priority;
      person.contactFrequencyGoalDays = _frequencyDays;
      person.updatedAt = DateTime.now();
      vm.updatePerson(FamilyPerson(
        id: person.id,
        fullName: _nameCtrl.text.trim(),
        relationshipType: _relationship,
        nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
        birthday: _birthday,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        notesSummary: _notesCtrl.text,
        lastContactAt: person.lastContactAt,
        contactFrequencyGoalDays: _frequencyDays,
        priorityLevel: _priority,
        tags: person.tags,
        createdAt: person.createdAt,
      ));
    } else {
      vm.addPerson(FamilyPerson(
        fullName: _nameCtrl.text.trim(),
        relationshipType: _relationship,
        nickname: _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
        birthday: _birthday,
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        notesSummary: _notesCtrl.text,
        contactFrequencyGoalDays: _frequencyDays,
        priorityLevel: _priority,
      ));
    }
    Navigator.pop(context);
  }
}

class _RelationshipPicker extends StatelessWidget {
  final RelationshipType selected;
  final void Function(RelationshipType) onChanged;
  const _RelationshipPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RelationshipType.values.map((r) {
        final isSelected = r == selected;
        return GestureDetector(
          onTap: () => onChanged(r),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
            child: Text(
              '${r.emoji} ${r.label}',
              style: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PriorityPicker extends StatelessWidget {
  final PriorityLevel selected;
  final void Function(PriorityLevel) onChanged;
  const _PriorityPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (PriorityLevel.low, 'Low', AppColors.textMuted),
      (PriorityLevel.medium, 'Medium', AppColors.accent),
      (PriorityLevel.high, 'High', AppColors.accentRed),
      (PriorityLevel.critical, 'Critical ❤️', const Color(0xFFEC4899)),
    ];

    return Row(
      children: options.map((opt) {
        final (level, label, color) = opt;
        final isSelected = level == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: Container(
              margin: EdgeInsets.only(right: level != PriorityLevel.critical ? 6 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? color : AppColors.textMuted,
                ),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected ? color : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateRow extends StatelessWidget {
  final DateTime? date;
  final String hint;
  final void Function(DateTime) onPick;
  final VoidCallback onClear;
  const _DateRow(
      {required this.date,
      required this.hint,
      required this.onPick,
      required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime(1990),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark()
                .copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primary)),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textMuted),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date!.month}/${date!.day}/${date!.year}'
                    : hint,
                style: TextStyle(
                  color: date != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyPicker extends StatelessWidget {
  final int? days;
  final void Function(int?) onChanged;
  const _FrequencyPicker({required this.days, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (null, 'None'),
      (3, '3d'),
      (7, '7d'),
      (14, '2w'),
      (30, '1mo'),
      (60, '2mo'),
    ];

    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final (value, label) = opt;
        final isSelected = value == days;
        return GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            child: Text(label,
                style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12)),
          ),
        );
      }).toList(),
    );
  }
}
