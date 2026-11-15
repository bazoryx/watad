import 'dart:convert';
import 'dart:math' as math;

/// A mosque found near the user. Pure Dart so the parsing and sorting are
/// covered by tests without any network or GPS.
class Mosque {
  final String? name;
  final String? nameAr;
  final String? nameEn;
  final double lat;
  final double lng;
  final double distanceM;

  const Mosque({
    this.name,
    this.nameAr,
    this.nameEn,
    required this.lat,
    required this.lng,
    required this.distanceM,
  });

  /// The name in the user's language, or null when the map has none.
  String? displayName(bool ar) =>
      ar ? (nameAr ?? name ?? nameEn) : (nameEn ?? name ?? nameAr);
}

/// Great-circle distance in meters (haversine).
double distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final sa = math.sin(dLat / 2);
  final sb = math.sin(dLng / 2);
  final a = sa * sa + math.cos(rad(lat1)) * math.cos(rad(lat2)) * sb * sb;
  return 2 * earthRadius * math.asin(math.sqrt(a));
}

/// Overpass (OpenStreetMap) query for mosques within [radiusM] meters.
String overpassQuery(double lat, double lng, int radiusM) {
  final around = '(around:$radiusM,$lat,$lng)';
  return '[out:json][timeout:20];('
      'node["amenity"="place_of_worship"]["religion"="muslim"]$around;'
      'way["amenity"="place_of_worship"]["religion"="muslim"]$around;'
      ');out center 60;';
}

/// Turns an Overpass JSON answer into mosques sorted by distance from
/// ([lat], [lng]), nearest first, at most [limit].
List<Mosque> parseMosques(String body, double lat, double lng, {int limit = 10}) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final elements = (data['elements'] as List? ?? const []).cast<Map<String, dynamic>>();
  final seen = <String>{};
  final out = <Mosque>[];
  for (final e in elements) {
    final id = '${e['type']}${e['id']}';
    if (!seen.add(id)) continue;
    final center = e['center'] as Map?;
    final mLat = (e['lat'] ?? center?['lat']) as num?;
    final mLng = (e['lon'] ?? center?['lon']) as num?;
    if (mLat == null || mLng == null) continue;
    final tags = (e['tags'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    out.add(Mosque(
      name: tags['name'] as String?,
      nameAr: tags['name:ar'] as String?,
      nameEn: tags['name:en'] as String?,
      lat: mLat.toDouble(),
      lng: mLng.toDouble(),
      distanceM: distanceMeters(lat, lng, mLat.toDouble(), mLng.toDouble()),
    ));
  }
  out.sort((a, b) => a.distanceM.compareTo(b.distanceM));
  return out.take(limit).toList();
}
