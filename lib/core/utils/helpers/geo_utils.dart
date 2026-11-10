import 'dart:math' show cos, sqrt, asin;

class GeoUtils {
  GeoUtils._();

  static double calculateDistance(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const earthRadiusKm = 6371.0;
    const degToRad = 0.017453292519943295;

    final dLat = (lat2 - lat1) * degToRad;
    final dLon = (lon2 - lon1) * degToRad;

    final a = 0.5 - cos(dLat) / 2 + cos(lat1 * degToRad) * cos(lat2 * degToRad) * (1 - cos(dLon)) / 2;

    return earthRadiusKm * 2 * asin(sqrt(a)) * 1000;
  }
}
