import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:sampriti/core/utils/helpers/geo_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart' hide Location;

class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();

  final Location _location = Location();

  /// Permission Handling
  Future<bool> _requestPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  /// Get Current Location
  Future<LocationData?> getCurrentLocation() async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return null;

    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return null;
    }

    try {
      return await _location.getLocation();
    } catch (e) {
      debugPrint("Location error: $e");
      return null;
    }
  }

  /// Reverse Geocoding (Address)
  Future<String?> getCurrentAddress() async {
    final locationData = await getCurrentLocation();
    if (locationData == null) return null;

    try {
      final placemarks = await placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isEmpty) return null;

      final place = placemarks.first;

      final address = [
        place.name,
        place.subThoroughfare,
        place.thoroughfare,
        place.subLocality,
        place.locality,
        place.country,
      ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

      return address;
    } catch (e) {
      debugPrint("Geocoding error: $e");
      return null;
    }
  }

  /// Attendance Radius Validation
  Future<bool> isWithinRadius({
    required double targetLat,
    required double targetLng,
    required double radiusMeters,
  }) async {
    final locationData = await getCurrentLocation();
    if (locationData == null) return false;

    final distance = GeoUtils.calculateDistance(
      targetLat,
      targetLng,
      locationData.latitude!,
      locationData.longitude!,
    );

    debugPrint("Distance from target: $distance m");

    return distance <= radiusMeters;
  }
}
