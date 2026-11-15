import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models.dart';
import '../core/reminders.dart';

/// Local storage for the first build (no accounts yet). Logs and excuses
/// are kept as JSON. Moving to a cloud backend later only replaces this
/// class.
class Repository {
  static const _kLogs = 'logs_v1';
  static const _kExcuses = 'excuses_v1';
  static const _kStart = 'start_day';
  static const _kCity = 'city';
  static const _kLocale = 'locale';
  static const _kAutoFreeze = 'auto_freeze';
  static const _kHideMosque = 'hide_mosque';
  static const _kReminders = 'reminders_v1';

  final SharedPreferences _p;
  Repository(this._p);

  static Future<Repository> open() async =>
      Repository(await SharedPreferences.getInstance());

  Map<String, PrayerLog> loadLogs() {
    final raw = _p.getString(_kLogs);
    if (raw == null) return {};
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final logs = list.map(PrayerLog.fromJson);
    return {for (final l in logs) l.key: l};
  }

  Future<void> saveLogs(Map<String, PrayerLog> logs) => _p.setString(
      _kLogs, jsonEncode(logs.values.map((l) => l.toJson()).toList()));

  List<Excuse> loadExcuses() {
    final raw = _p.getString(_kExcuses);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(Excuse.fromJson)
        .toList();
  }

  Future<void> saveExcuses(List<Excuse> e) => _p.setString(
      _kExcuses, jsonEncode(e.map((x) => x.toJson()).toList()));

  /// First day tracked: the install day, stored on first launch.
  DateTime startDay() {
    final s = _p.getString(_kStart);
    if (s != null) return parseDayKey(s);
    final today = dayOf(DateTime.now());
    _p.setString(_kStart, dayKey(today));
    return today;
  }

  String get cityId => _p.getString(_kCity) ?? 'dubai';
  set cityId(String v) => _p.setString(_kCity, v);

  String get locale => _p.getString(_kLocale) ?? 'ar';
  set locale(String v) => _p.setString(_kLocale, v);

  bool get autoFreeze => _p.getBool(_kAutoFreeze) ?? true;
  set autoFreeze(bool v) => _p.setBool(_kAutoFreeze, v);

  bool get hideMosque => _p.getBool(_kHideMosque) ?? false;
  set hideMosque(bool v) => _p.setBool(_kHideMosque, v);

  ReminderSettings get reminders {
    final raw = _p.getString(_kReminders);
    if (raw == null) return ReminderSettings.defaults();
    return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  set reminders(ReminderSettings v) =>
      _p.setString(_kReminders, jsonEncode(v.toJson()));
}
