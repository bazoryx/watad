import 'package:adhan/adhan.dart' as adhan;
import 'models.dart';

/// Preset cities for the first build. Each uses the calculation method of
/// its country, so times work offline. GPS-based location arrives with the
/// "nearest mosque" feature.
class City {
  final String id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  final adhan.CalculationMethod method;

  const City(this.id, this.nameAr, this.nameEn, this.lat, this.lng, this.method);
}

const kCities = <City>[
  City('dubai', 'دبي', 'Dubai', 25.2048, 55.2708, adhan.CalculationMethod.dubai),
  City('abudhabi', 'أبوظبي', 'Abu Dhabi', 24.4539, 54.3773, adhan.CalculationMethod.dubai),
  City('sharjah', 'الشارقة', 'Sharjah', 25.3463, 55.4209, adhan.CalculationMethod.dubai),
  City('ajman', 'عجمان', 'Ajman', 25.4052, 55.5136, adhan.CalculationMethod.dubai),
  City('rak', 'رأس الخيمة', 'Ras Al Khaimah', 25.8007, 55.9762, adhan.CalculationMethod.dubai),
  City('fujairah', 'الفجيرة', 'Fujairah', 25.1288, 56.3265, adhan.CalculationMethod.dubai),
  City('alain', 'العين', 'Al Ain', 24.2075, 55.7447, adhan.CalculationMethod.dubai),
  City('riyadh', 'الرياض', 'Riyadh', 24.7136, 46.6753, adhan.CalculationMethod.umm_al_qura),
  City('jeddah', 'جدة', 'Jeddah', 21.4858, 39.1925, adhan.CalculationMethod.umm_al_qura),
  City('makkah', 'مكة المكرمة', 'Makkah', 21.3891, 39.8579, adhan.CalculationMethod.umm_al_qura),
  City('madinah', 'المدينة المنورة', 'Madinah', 24.5247, 39.5692, adhan.CalculationMethod.umm_al_qura),
  City('dammam', 'الدمام', 'Dammam', 26.4207, 50.0888, adhan.CalculationMethod.umm_al_qura),
  City('kuwait', 'الكويت', 'Kuwait City', 29.3759, 47.9774, adhan.CalculationMethod.kuwait),
  City('doha', 'الدوحة', 'Doha', 25.2854, 51.5310, adhan.CalculationMethod.qatar),
];

City cityById(String id) =>
    kCities.firstWhere((c) => c.id == id, orElse: () => kCities.first);

/// Default minutes between adhan and iqama (UAE practice). User-editable
/// per prayer in a later build.
const kIqamaMinutes = <Prayer, int>{
  Prayer.fajr: 25,
  Prayer.dhuhr: 20,
  Prayer.asr: 20,
  Prayer.maghrib: 5,
  Prayer.isha: 20,
};

class PrayerTimesService {
  /// Adhan times for [day] in the device's local time zone. Assumes the
  /// device is in the chosen city's time zone (true for users at home).
  static Map<Prayer, DateTime> forDay(City city, DateTime day) {
    final params = city.method.getParameters();
    final pt = adhan.PrayerTimes(
      adhan.Coordinates(city.lat, city.lng),
      adhan.DateComponents(day.year, day.month, day.day),
      params,
    );
    return {
      Prayer.fajr: pt.fajr,
      Prayer.dhuhr: pt.dhuhr,
      Prayer.asr: pt.asr,
      Prayer.maghrib: pt.maghrib,
      Prayer.isha: pt.isha,
    };
  }

  /// The next adhan after [now] (tomorrow's Fajr after Isha).
  static ({Prayer prayer, DateTime time}) next(City city, DateTime now) {
    final today = forDay(city, now);
    for (final p in Prayer.values) {
      if (today[p]!.isAfter(now)) return (prayer: p, time: today[p]!);
    }
    final tomorrow = forDay(city, nextDay(dayOf(now)));
    return (prayer: Prayer.fajr, time: tomorrow[Prayer.fajr]!);
  }
}
