import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/mosques.dart';

class MosqueSearchException implements Exception {
  const MosqueSearchException();
}

/// Finds mosques through the free Overpass API (OpenStreetMap data).
class MosqueFinder {
  final http.Client _client;
  MosqueFinder([http.Client? client]) : _client = client ?? http.Client();

  Future<List<Mosque>> nearby(double lat, double lng) async {
    try {
      for (final radius in const [3000, 8000]) {
        final res = await _client
            .post(Uri.parse('https://overpass-api.de/api/interpreter'),
                body: {'data': overpassQuery(lat, lng, radius)})
            .timeout(const Duration(seconds: 25));
        if (res.statusCode != 200) throw const MosqueSearchException();
        final list = parseMosques(utf8.decode(res.bodyBytes), lat, lng);
        if (list.isNotEmpty) return list;
      }
      return const [];
    } on MosqueSearchException {
      rethrow;
    } catch (_) {
      throw const MosqueSearchException();
    }
  }
}
