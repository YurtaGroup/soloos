import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/google_calendar_service.dart';
import '../services/locale_service.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _calService = GoogleCalendarService();

  @override
  void initState() {
    super.initState();
    _calService.addListener(_onUpdate);
    _calService.tryAutoSignIn();
  }

  @override
  void dispose() {
    _calService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(ls.t('calendar_title')),
        actions: [
          if (_calService.isSignedIn)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.accentBlue),
              onPressed: _calService.fetchEvents,
            ),
        ],
      ),
      body: !_calService.isSignedIn
          ? _ConnectView(service: _calService)
          : _CalendarView(service: _calService),
    );
  }
}

class _ConnectView extends StatelessWidget {
  final GoogleCalendarService service;
  const _ConnectView({required this.service});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: AppColors.accentBlue, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              ls.t('connect_google_cal'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ls.t('google_cal_subtitle'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (service.loading)
              const CircularProgressIndicator(color: AppColors.accentBlue)
            else
              ElevatedButton.icon(
                onPressed: service.signIn,
                icon: const Text('G', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                label: Text(ls.t('sign_in_google')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1A73E8),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            if (service.error != null) ...[
              const SizedBox(height: 12),
              Text(
                service.error!,
                style: const TextStyle(color: AppColors.accentRed, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarView extends StatelessWidget {
  final GoogleCalendarService service;
  const _CalendarView({required this.service});

  @override
  Widget build(BuildContext context) {
    if (service.loading) {
      return const Center(child: AiThinkingWidget(message: 'Syncing calendar...'));
    }

    final todayEvents = service.todayEvents;
    final weekEvents = service.weekEvents;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connected banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${ls.t('connected')}: ${service.userEmail}',
                  style: const TextStyle(color: AppColors.accentGreen, fontSize: 13),
                ),
              ),
              GestureDetector(
                onTap: service.signOut,
                child: Text(
                  ls.t('sign_out'),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Today
        _SectionHeader(
          title: ls.t('today_events'),
          subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
          color: AppColors.primary,
          icon: Icons.today_rounded,
        ),
        const SizedBox(height: 10),
        if (todayEvents.isEmpty)
          _EmptyDay(message: ls.t('no_events_sub'))
        else
          ...todayEvents.map((e) => _EventCard(event: e)),

        const SizedBox(height: 24),

        // This week
        _SectionHeader(
          title: ls.t('week_events'),
          color: AppColors.accentBlue,
          icon: Icons.view_week_rounded,
        ),
        const SizedBox(height: 10),
        if (weekEvents.isEmpty)
          _EmptyDay(message: ls.t('no_events_sub'))
        else
          ...weekEvents.map((e) => _EventCard(event: e)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
            if (subtitle != null)
              Text(subtitle!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  const _EventCard({required this.event});

  Color get _eventColor {
    switch (event.colorId) {
      case '1': return const Color(0xFF7986CB); // lavender
      case '2': return const Color(0xFF33B679); // sage
      case '3': return const Color(0xFF8E24AA); // grape
      case '4': return const Color(0xFFE67C73); // flamingo
      case '5': return const Color(0xFFF6BF26); // banana
      case '6': return const Color(0xFFFF8A65); // tangerine
      case '7': return AppColors.accentBlue;     // peacock
      case '9': return AppColors.accentBlue;     // blueberry
      case '10': return AppColors.accentGreen;   // basil
      case '11': return const Color(0xFFD50000); // tomato
      default: return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor;
    final timeStr = event.isAllDay
        ? 'All day'
        : '${DateFormat.jm().format(event.start)} – ${DateFormat.jm().format(event.end)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(child: Text(event.location!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(timeStr, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final String message;
  const _EmptyDay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
