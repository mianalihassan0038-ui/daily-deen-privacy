import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../data/cities.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String name;
  const LocationResult(this.lat, this.lng, this.name);
}

enum LocationError { serviceDisabled, denied, deniedForever, failed }

class LocationException implements Exception {
  final LocationError error;
  const LocationException(this.error);
}

double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

/// Name of the nearest listed city within 60 km, otherwise null.
String? nearestCityName(double lat, double lng) {
  City? best;
  var bestD = double.infinity;
  for (final c in cities) {
    final d = distanceKm(lat, lng, c.lat, c.lng);
    if (d < bestD) {
      bestD = d;
      best = c;
    }
  }
  return bestD <= 60 ? best?.name : null;
}

/// Reads the device position (coarse accuracy is enough for prayer times).
Future<LocationResult> currentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationException(LocationError.serviceDisabled);
  }
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied) throw const LocationException(LocationError.denied);
  if (perm == LocationPermission.deniedForever) throw const LocationException(LocationError.deniedForever);
  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
    );
    final name = nearestCityName(pos.latitude, pos.longitude) ?? '';
    return LocationResult(pos.latitude, pos.longitude, name);
  } catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      return LocationResult(last.latitude, last.longitude, nearestCityName(last.latitude, last.longitude) ?? '');
    }
    throw const LocationException(LocationError.failed);
  }
}

Future<void> openAppSettings() => Geolocator.openAppSettings();
Future<void> openLocationSettings() => Geolocator.openLocationSettings();
