import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis/people/v1.dart' as gpeople;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/app_models.dart';
import 'package:uuid/uuid.dart';

class GoogleCalendarService extends ChangeNotifier {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn {
    _googleSignInInstance ??= GoogleSignIn(
      scopes: [
        gcal.CalendarApi.calendarReadonlyScope,
        gcal.CalendarApi.calendarEventsScope,
        gpeople.PeopleServiceApi.contactsReadonlyScope,
      ],
    );
    return _googleSignInInstance!;
  }

  GoogleSignInAccount? _currentUser;
  bool get isSignedIn => _currentUser != null;
  String get userEmail => _currentUser?.email ?? '';
  String get userName => _currentUser?.displayName ?? '';
  bool _loading = false;
  bool get loading => _loading;
  String? _error;
  String? get error => _error;

  List<CalendarEvent> _events = [];
  List<CalendarEvent> get events => _events;

  List<CalendarEvent> get todayEvents {
    final now = DateTime.now();
    return _events.where((e) {
      final start = e.start;
      return start.year == now.year && start.month == now.month && start.day == now.day;
    }).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<CalendarEvent> get weekEvents {
    final now = DateTime.now();
    final endOfWeek = now.add(Duration(days: 7 - now.weekday));
    return _events.where((e) => e.start.isAfter(now) && e.start.isBefore(endOfWeek)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  // ─── Sign In ──────────────────────────────────────────────────
  Future<bool> signIn() async {
    try {
      _setLoading(true);
      _error = null;
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      if (account != null) {
        await fetchEvents();
      }
      _setLoading(false);
      return account != null;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _events = [];
    notifyListeners();
  }

  Future<void> tryAutoSignIn() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      if (account != null) await fetchEvents();
    } catch (e) {
      debugPrint('Google auto sign-in failed: $e');
    }
  }

  // ─── Fetch Events ─────────────────────────────────────────────
  Future<void> fetchEvents() async {
    if (_currentUser == null) return;
    try {
      _setLoading(true);
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return;

      final calApi = gcal.CalendarApi(httpClient);
      final now = DateTime.now();
      final response = await calApi.events.list(
        'primary',
        timeMin: DateTime(now.year, now.month, now.day),
        timeMax: DateTime(now.year, now.month, now.day + 14),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 50,
      );

      _events = (response.items ?? [])
          .where((e) => e.start != null)
          .map((e) => CalendarEvent(
                id: e.id ?? const Uuid().v4(),
                title: e.summary ?? '(No title)',
                start: e.start?.dateTime?.toLocal() ?? e.start!.date!,
                end: e.end?.dateTime?.toLocal() ?? e.end!.date!,
                isAllDay: e.start?.dateTime == null,
                location: e.location,
                description: e.description,
                colorId: e.colorId,
              ))
          .toList();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // ─── Create Event ─────────────────────────────────────────────
  Future<bool> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    String? location,
  }) async {
    if (_currentUser == null) return false;
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      final calApi = gcal.CalendarApi(httpClient);
      final event = gcal.Event()
        ..summary = title
        ..description = description
        ..location = location
        ..start = (gcal.EventDateTime()..dateTime = start..timeZone = 'UTC')
        ..end = (gcal.EventDateTime()..dateTime = end..timeZone = 'UTC');

      await calApi.events.insert(event, 'primary');
      await fetchEvents();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ─── Add Local Event (when not signed in to Google) ──────────
  void addLocalEvent(CalendarEvent event) {
    _events.add(event);
    notifyListeners();
  }

  // ─── Import Birthdays from Google Contacts ───────────────────
  Future<List<Contact>> importBirthdays() async {
    if (_currentUser == null) return [];
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return [];

      final peopleApi = gpeople.PeopleServiceApi(httpClient);
      final response = await peopleApi.people.connections.list(
        'people/me',
        personFields: 'names,birthdays,emailAddresses,photos',
        pageSize: 200,
      );

      final contacts = <Contact>[];
      for (final person in response.connections ?? []) {
        final bday = person.birthdays?.firstOrNull;
        final name = person.names?.firstOrNull?.displayName;
        if (bday == null || name == null) continue;

        final date = bday.date;
        if (date == null || date.month == null || date.day == null) continue;

        contacts.add(Contact(
          id: person.resourceName ?? const Uuid().v4(),
          name: name,
          birthday: DateTime(
            date.year ?? DateTime.now().year,
            date.month!,
            date.day!,
          ),
          emoji: '👤',
          relationship: 'contact',
        ));
      }
      return contacts;
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}

// ─── Model ────────────────────────────────────────────────────────
class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final bool isAllDay;
  final String? location;
  final String? description;
  final String? colorId;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.isAllDay = false,
    this.location,
    this.description,
    this.colorId,
  });
}
