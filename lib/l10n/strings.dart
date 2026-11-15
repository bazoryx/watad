import 'package:flutter/widgets.dart';
import '../core/models.dart';
import '../core/reminders.dart';

/// Arabic and English UI text. A plain map instead of gen-l10n, so the
/// project builds the same on every Flutter version with no code generation.
class S {
  final bool ar;
  const S(this.ar);

  static S of(BuildContext context) =>
      S(Localizations.localeOf(context).languageCode == 'ar');

  String t(String a, String e) => ar ? a : e;

  String get appName => t('وتد', 'Watad');
  String get home => t('الرئيسية', 'Home');
  String get calendar => t('التقويم', 'Calendar');
  String get settings => t('الإعدادات', 'Settings');

  String prayer(Prayer p) => switch (p) {
        Prayer.fajr => t('الفجر', 'Fajr'),
        Prayer.dhuhr => t('الظهر', 'Dhuhr'),
        Prayer.asr => t('العصر', 'Asr'),
        Prayer.maghrib => t('المغرب', 'Maghrib'),
        Prayer.isha => t('العشاء', 'Isha'),
      };

  String get nextPrayer => t('الصلاة القادمة', 'Next prayer');
  String iqamaAt(String time) => t('الإقامة $time', 'Iqama $time');
  String get mosqueStreak => t('ستريك المسجد', 'Mosque streak');
  String get maintenanceStreak => t('ستريك المحافظة', 'On-time streak');
  String get consecutivePrayers => t('صلاة متتالية', 'prayers in a row');
  String best(int n) => t('أفضل رقم: $n', 'Best: $n');
  String get mosqueOrHome => t('مسجد أو بيت', 'Mosque or home');
  String get todaysPrayers => t('صلوات اليوم', "Today's prayers");
  String loggedOf(int n) => t('$n من 5', '$n of 5');
  String get score => t('السكور', 'Score');
  String points(int n) => t('$n نقطة', '$n pts');

  String outcome(SlotOutcome o) => switch (o) {
        SlotOutcome.mosque => t('في المسجد', 'At the mosque'),
        SlotOutcome.home => t('في البيت', 'At home'),
        SlotOutcome.qada => t('قضاء في وقته', 'Made up in time'),
        SlotOutcome.lateQada => t('قضاء متأخر', 'Made up late'),
        SlotOutcome.missed => t('فاتت', 'Missed'),
        SlotOutcome.excused => t('عذر', 'Excused'),
        SlotOutcome.frozen => t('محميّة بالتجميد', 'Covered by a freeze'),
        SlotOutcome.pending => t('لم تُسجَّل', 'Not logged'),
      };

  // Log sheet
  String wherePrayed(Prayer p) =>
      t('أين صليت ${prayer(p)}؟', 'Where did you pray ${prayer(p)}?');
  String get atMosque => t('في المسجد', 'At the mosque');
  String get atMosqueSub => t('يرفع ستريك المسجد والمحافظة', 'Raises both streaks');
  String get atHome => t('في البيت أو العمل', 'At home or work');
  String get atHomeSub =>
      t('يرفع المحافظة · ستريك المسجد يرجع للصفر', 'Raises on-time · resets mosque');
  String get qada => t('قضيتها قبل الصلاة التالية', 'Made up before the next prayer');
  String get qadaSub => t('ستريك المحافظة يبقى', 'On-time streak stays');
  String get lateQada => t('قضيتها بعد دخول التالية', 'Made up after the next one');
  String get lateQadaSub => t('نقطة واحدة · المحافظة ترجع للصفر', '1 point · resets on-time');
  String get missed => t('لم أصلّها', 'I did not pray it');
  String get clearLog => t('مسح التسجيل', 'Clear entry');
  String get locationConfirm => t('تأكيد بالموقع (قريبًا)', 'Confirm by location (soon)');
  String get excusedDay => t('أنت في عذر اليوم، والصلاة غير المسجلة لا تكسر الستريك',
      "You have an excuse today; unlogged prayers won't break your streak");

  // Status banners
  String freezesLeft(int n) => n == 1
      ? t('بقي تجميد واحد هذا الشهر', '1 freeze left this month')
      : t('بقي $n تجميد هذا الشهر', '$n freezes left this month');
  String activeExcuse(String type) => t('عذر نشط · $type', 'Active excuse · $type');
  String get streakSafe => t('ستريكك محفوظ ولن ينكسر', 'Your streak is safe');
  String get endExcuse => t('انتهى العذر', 'End excuse');

  String excuseType(ExcuseType type) => switch (type) {
        ExcuseType.travel => t('سفر', 'Travel'),
        ExcuseType.illness => t('مرض', 'Illness'),
        ExcuseType.menstruation => t('عذر المرأة', "Women's excuse"),
      };

  // Calendar
  List<String> get weekdaysShort => ar
      ? const ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة']
      : const ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  String monthName(int m) => (ar
      ? const ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
      : const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'])[m - 1];
  String get legendMosque => t('مسجد', 'Mosque');
  String get legendHome => t('بيت', 'Home');
  String get legendQada => t('قضاء', 'Made up');
  String get legendMissed => t('فائتة', 'Missed');
  String get legendExcused => t('عذر أو تجميد', 'Excuse or freeze');
  String get monthStats => t('إحصائيات الشهر', 'This month');
  String get tapDay => t('اختر يومًا لعرض صلواته', 'Pick a day to see its prayers');
  String get futureDay => t('هذا اليوم لم يأتِ بعد', 'This day has not come yet');
  String get beforeStart => t('قبل بداية استخدامك للتطبيق', 'Before you started using the app');

  // Settings
  String get city => t('المدينة', 'City');
  String get calcNote => t('المواقيت تُحسب على الجهاز بطريقة حساب دولة المدينة',
      "Times are calculated on the device with the city's official method");
  String get language => t('اللغة', 'Language');
  String get autoFreeze => t('حماية الستريك تلقائيًا', 'Protect streak automatically');
  String get autoFreezeSub => t('تجميدان في الشهر إذا نسيت التسجيل', 'Two freezes a month if you forget to log');
  String get hideMosque => t('إخفاء ستريك المسجد', 'Hide mosque streak');
  String get hideMosqueSub => t('للأخوات: الاكتفاء بستريك المحافظة', 'Keep only the on-time streak');
  String get excuses => t('الأعذار', 'Excuses');
  String get startExcuse => t('بدء عذر من اليوم', 'Start an excuse today');
  String get excusePrivacy => t('المجموعة ترى كلمة «عذر» فقط، بدون نوعه',
      'Your group only sees "excused", never the type');
  // Reminders
  String get remindersTitle => t('التنبيهات والأذان', 'Reminders & adhan');
  String get remindersOn => t('تفعيل التنبيهات', 'Turn on reminders');
  String get remindPrayers => t('الصلوات', 'Prayers');
  String get remindBefore => t('تنبيه قبل الأذان', 'Reminder before adhan');
  String get off => t('بدون', 'Off');
  String minutesBefore(int m) => t('قبل $m دقيقة', '$m min before');
  String get iqamaReminder => t('تنبيه الإقامة', 'Iqama reminder');
  String get adhanVoice => t('صوت الأذان', 'Adhan voice');
  String get voiceMakkah => t('مكة', 'Makkah');
  String get voiceMadinah => t('المدينة', 'Madinah');
  String get upcoming => t('التنبيهات القادمة', 'Upcoming reminders');
  String get todayLabel => t('اليوم', 'Today');
  String get tomorrowLabel => t('غدًا', 'Tomorrow');
  String reminderKind(ReminderKind k) => switch (k) {
        ReminderKind.before => t('قبل الأذان', 'Before adhan'),
        ReminderKind.adhan => t('الأذان', 'Adhan'),
        ReminderKind.iqama => t('الإقامة', 'Iqama'),
      };
  String get remindersNote => t(
      'التنبيه في الخلفية وصوت الأذان يشتغلان في نسخة الآيفون. معاينة الويب تعرض الجدول فقط.',
      'Background alerts and adhan audio work in the iPhone build. The web preview only shows the schedule.');
  String get noExcuse => t('لا يوجد عذر نشط', 'No active excuse');
}

/// "3:13 م" / "3:13 PM" with Latin digits, matching the design.
String formatTime(DateTime t, S s) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  final pm = t.hour >= 12;
  return s.ar ? '$h:$m ${pm ? 'م' : 'ص'}' : '$h:$m ${pm ? 'PM' : 'AM'}';
}

String formatCountdown(Duration d) {
  final h = d.inHours.toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$h:$m:$sec';
}
