import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:watad/core/mosques.dart';

void main() {
  test('distance Dubai to Abu Dhabi is about 130 km', () {
    final d = distanceMeters(25.2048, 55.2708, 24.4539, 54.3773);
    expect(d, inInclusiveRange(120000, 140000));
  });

  test('distance to the same point is zero', () {
    expect(distanceMeters(25.0, 55.0, 25.0, 55.0), closeTo(0, 0.001));
  });

  final sample = jsonEncode({
    'elements': [
      {
        'type': 'node', 'id': 1, 'lat': 25.2100, 'lon': 55.2700,
        'tags': {'name': 'Far Mosque', 'name:ar': 'مسجد بعيد'}
      },
      {
        'type': 'way', 'id': 2,
        'center': {'lat': 25.2050, 'lon': 55.2710},
        'tags': {'name:en': 'Near Mosque'}
      },
      {'type': 'node', 'id': 3, 'lat': 25.2060, 'lon': 55.2720},
      {'type': 'node', 'id': 3, 'lat': 25.2060, 'lon': 55.2720},
      {'type': 'relation', 'id': 4},
    ]
  });

  test('parse sorts nearest first, reads ways, skips duplicates and bad rows', () {
    final list = parseMosques(sample, 25.2048, 55.2708);
    expect(list.length, 3);
    expect(list.first.nameEn, 'Near Mosque');
    for (var i = 1; i < list.length; i++) {
      expect(list[i].distanceM >= list[i - 1].distanceM, isTrue);
    }
  });

  test('names follow the language, unnamed gives null', () {
    final list = parseMosques(sample, 25.2048, 55.2708);
    final far = list.firstWhere((m) => m.name == 'Far Mosque');
    expect(far.displayName(true), 'مسجد بعيد');
    expect(far.displayName(false), 'Far Mosque');
    final unnamed = list.firstWhere((m) => m.name == null && m.nameEn == null);
    expect(unnamed.displayName(true), isNull);
  });

  test('limit is respected and empty answers are fine', () {
    expect(parseMosques(sample, 25.2048, 55.2708, limit: 1).length, 1);
    expect(parseMosques('{"elements": []}', 25.0, 55.0), isEmpty);
  });

  test('query asks for mosques around the point', () {
    final q = overpassQuery(25.2, 55.3, 3000);
    expect(q, contains('around:3000,25.2,55.3'));
    expect(q, contains('"religion"="muslim"'));
  });
}
