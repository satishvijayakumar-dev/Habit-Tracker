import 'package:geolocator/geolocator.dart';

/// A coarse, privacy-preserving location.
///
/// ActivHealth reads precise GPS on-device, but only ever stores/shares this
/// rounded version (~1 km), so a member's exact location can never be derived
/// from the backend.
class CoarseLocation {
  final double lat;
  final double lng;
  const CoarseLocation(this.lat, this.lng);

  @override
  bool operator ==(Object other) =>
      other is CoarseLocation && other.lat == lat && other.lng == lng;

  @override
  int get hashCode => Object.hash(lat, lng);

  @override
  String toString() => 'CoarseLocation($lat, $lng)';
}

class GeoService {
  /// Decimal places to keep. 2 dp ≈ 1.1 km — coarse enough that the stored
  /// point can't pinpoint a home, precise enough for "groups near me".
  static const int coarsePrecision = 2;

  /// Rounds a precise GPS fix to the coarse grid we actually persist.
  /// Pure and side-effect free so it can be unit-tested.
  static CoarseLocation coarsen(double lat, double lng) {
    final factor = _pow10(coarsePrecision);
    return CoarseLocation(
      (lat * factor).roundToDouble() / factor,
      (lng * factor).roundToDouble() / factor,
    );
  }

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  /// Requests permission (if needed) and returns the device's CURRENT
  /// location already coarsened. Returns null if location is unavailable or
  /// the user declines — callers must treat location as optional.
  static Future<CoarseLocation?> currentCoarseLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // we only need ~1km anyway
        ),
      );
      return coarsen(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
