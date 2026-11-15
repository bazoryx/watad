import 'package:geolocator/geolocator.dart';

enum LocationProblem { denied, deniedForever, unavailable }

class LocationException implements Exception {
  final LocationProblem problem;
  const LocationException(this.problem);
}

/// One-shot position of the device. Asks for permission when needed. The
/// position is used right away and never stored.
Future<({double lat, double lng})> currentLocation() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationException(LocationProblem.deniedForever);
  }
  if (permission == LocationPermission.denied) {
    throw const LocationException(LocationProblem.denied);
  }
  try {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (lat: p.latitude, lng: p.longitude);
  } catch (_) {
    throw const LocationException(LocationProblem.unavailable);
  }
}
