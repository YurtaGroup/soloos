import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/locale_service.dart';
import '../services/google_calendar_service.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';
import 'package:uuid/uuid.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _storage = StorageService();
  final _calService = GoogleCalendarService();
  late List<Contact> _contacts;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _contacts = _storage.getContacts()
        ..sort((a, b) => a.daysUntilBirthday.compareTo(b.daysUntilBirthday));
    });
  }

  // ── Import from Google Contacts ───────────────────────────────
  Future<void> _importFromGoogle() async {
    if (!_calService.isSignedIn) {
      _snack(ls.t('connect_google'));
      return;
    }
    setState(() => _importing = true);
    final imported = await _calService.importBirthdays();
    if (imported.isEmpty) {
      setState(() => _importing = false);
      _snack('No birthdays found in Google Contacts');
      return;
    }

    final existing = _storage.getContacts();
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    int added = 0;
    for (final c in imported) {
      if (!existingNames.contains(c.name.toLowerCase())) {
        existing.add(c);
        added++;
      }
    }
    await _storage.saveContacts(existing);
    setState(() => _importing = false);
    _reload();
    _snack('Imported $added new contacts from Google');
  }

  // ── Quick Add Birthday (name + date only) ─────────────────────
  Future<void> _quickAddBirthday() async {
    final nameCtrl = TextEditingController();
    DateTime birthday = DateTime(1990, 6, 15);
    String emoji = '🎂';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(ls.t('quick_add_birthday'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(ls.t('quick_add_sub'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final emojis = ['🎂', '👤', '👨', '👩', '👴', '👵',
                                      '👦', '👧', '🧑', '❤️', '⭐', '🎉'];
                      final e = await showDialog<String>(
                        context: ctx,
                        builder: (d) => AlertDialog(
                          backgroundColor: AppColors.card,
                          title: const Text('Pick emoji',
                              style: TextStyle(color: AppColors.textPrimary)),
                          content: Wrap(
                            spacing: 12, runSpacing: 12,
                            children: emojis.map((e) => GestureDetector(
                              onTap: () => Navigator.pop(d, e),
                              child: Text(e, style: const TextStyle(fontSize: 28)),
                            )).toList(),
                          ),
                        ),
                      );
                      if (e != null) setModal(() => emoji = e);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(hintText: ls.t('name')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: birthday,
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                    builder: (ctx, child) => Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(primary: AppColors.primary),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setModal(() => birthday = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        ls.t('birthday_label', {'date': DateFormat('MMMM d').format(birthday)}),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final contacts = _storage.getContacts()
                      ..add(Contact(
                        id: const Uuid().v4(),
                        name: nameCtrl.text.trim(),
                        emoji: emoji,
                        birthday: birthday,
                        relationship: 'friend',
                      ));
                    await _storage.saveContacts(contacts);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _reload();
                  },
                  child: Text(ls.t('add_contact_btn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Full Add Contact ──────────────────────────────────────────
  Future<void> _addFullContact() async {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String emoji = '👤';
    String relationship = 'friend';
    DateTime birthday = DateTime(1990, 6, 15);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ls.t('add_contact'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        )),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final emojis = ['👤', '👨', '👩', '👴', '👵', '👦', '👧',
                                        '🧑', '👨‍💼', '👩‍💼', '🧑‍💻', '❤️', '⭐', '🎂'];
                        final e = await showDialog<String>(
                          context: ctx,
                          builder: (d) => AlertDialog(
                            backgroundColor: AppColors.card,
                            title: const Text('Pick emoji',
                                style: TextStyle(color: AppColors.textPrimary)),
                            content: Wrap(
                              spacing: 12, runSpacing: 12,
                              children: emojis.map((e) => GestureDetector(
                                onTap: () => Navigator.pop(d, e),
                                child: Text(e, style: const TextStyle(fontSize: 28)),
                              )).toList(),
                            ),
                          ),
                        );
                        if (e != null) setModal(() => emoji = e);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(hintText: ls.t('name')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: birthday,
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setModal(() => birthday = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.textMuted),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          ls.t('birthday_label', {'date': DateFormat('MMMM d').format(birthday)}),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: relationship,
                  style: const TextStyle(color: AppColors.textPrimary),
                  dropdownColor: AppColors.card,
                  decoration: const InputDecoration(hintText: 'Relationship'),
                  items: ['friend', 'family', 'partner', 'colleague', 'mentor', 'client']
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r[0].toUpperCase() + r.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) => setModal(() => relationship = v ?? relationship),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(hintText: 'Notes (optional)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final contacts = _storage.getContacts()
                        ..add(Contact(
                          id: const Uuid().v4(),
                          name: nameCtrl.text.trim(),
                          emoji: emoji,
                          birthday: birthday,
                          relationship: relationship,
                          notes: notesCtrl.text.trim(),
                        ));
                      await _storage.saveContacts(contacts);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _reload();
                    },
                    child: Text(ls.t('add_contact_btn')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final upcoming = _contacts.where((c) => c.daysUntilBirthday <= 30).toList();
    final rest = _contacts.where((c) => c.daysUntilBirthday > 30).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(ls.t('contacts_title')),
        actions: [
          if (_calService.isSignedIn)
            _importing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.accentBlue, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download_rounded, color: AppColors.accentBlue),
                    tooltip: 'Import from Google',
                    onPressed: _importFromGoogle,
                  ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppColors.accentRed),
            onPressed: _addFullContact,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Google import banner ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _calService.isSignedIn
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _importing ? null : _importFromGoogle,
                      icon: _importing
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.accentBlue),
                            )
                          : const Icon(Icons.download_rounded,
                              color: AppColors.accentBlue, size: 16),
                      label: Text(ls.t('import_google'),
                          style: const TextStyle(
                              color: AppColors.accentBlue, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accentBlue.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accentBlue.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_download_outlined,
                            color: AppColors.accentBlue, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ls.t('connect_google'),
                              style: const TextStyle(
                                  color: AppColors.accentBlue, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 4),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: _contacts.isEmpty
                ? EmptyState(
                    emoji: '🎂',
                    title: ls.t('no_contacts'),
                    subtitle: ls.t('no_contacts_sub'),
                    onAction: _quickAddBirthday,
                    actionLabel: ls.t('add_contact_btn'),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    children: [
                      if (upcoming.isNotEmpty) ...[
                        Text(ls.t('upcoming_birthdays'),
                            style: const TextStyle(
                              color: AppColors.accentRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 10),
                        ...upcoming.map((c) => _ContactCard(
                              contact: c,
                              onDelete: () async {
                                _contacts.remove(c);
                                await _storage.saveContacts(_contacts);
                                _reload();
                              },
                            )),
                        const SizedBox(height: 16),
                      ],
                      if (rest.isNotEmpty) ...[
                        Text(ls.t('all_contacts'),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 10),
                        ...rest.map((c) => _ContactCard(
                              contact: c,
                              onDelete: () async {
                                _contacts.remove(c);
                                await _storage.saveContacts(_contacts);
                                _reload();
                              },
                            )),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'quick',
            onPressed: _quickAddBirthday,
            backgroundColor: AppColors.surface,
            child: const Icon(Icons.flash_on_rounded,
                color: AppColors.accent, size: 18),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'full',
            onPressed: _addFullContact,
            backgroundColor: AppColors.accentRed,
            child: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onDelete;
  const _ContactCard({required this.contact, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final days = contact.daysUntilBirthday;
    final daysColor = days == 0
        ? AppColors.accentRed
        : days <= 7
            ? AppColors.accent
            : AppColors.textSecondary;

    return Dismissible(
      key: Key(contact.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.accentRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.accentRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: days == 0
              ? Border.all(color: AppColors.accentRed.withOpacity(0.5))
              : days <= 7
                  ? Border.all(color: AppColors.accent.withOpacity(0.3))
                  : null,
        ),
        child: Row(
          children: [
            Text(contact.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      )),
                  Text(
                    '${contact.relationship[0].toUpperCase()}${contact.relationship.substring(1)} · ${DateFormat('MMMM d').format(contact.birthday)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: daysColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                days == 0 ? ls.t('today_birthday') : 'in ${days}d',
                style: TextStyle(
                  color: daysColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
