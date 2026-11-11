import 'dart:math';

class GeofenceEngine {
  static const double earthRadiusMeters = 6371000.0;
  static const double degToRad = pi / 180.0;

  /// Determines whether a coordinate [lat, lng] falls within the polygon boundary
  /// using the Ray-Casting Point-in-Polygon (PIP) algorithm (Even-Odd Rule).
  static bool isPointInPolygon(
    double lat,
    double lng,
    List<List<double>> polygon,
  ) {
    if (polygon.length < 3) return false;

    // First check if the point lies directly on any edge segment
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (_isPointOnSegment(lat, lng, polygon[j], polygon[i])) {
        return true;
      }
    }

    bool inside = false;
    final int n = polygon.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final double xi = polygon[i][0]; // latitude
      final double yi = polygon[i][1]; // longitude
      final double xj = polygon[j][0];
      final double yj = polygon[j][1];

      // Check if the ray from (lat, lng) extends across the longitude span of the edge
      final bool crossesLongitude = (yi > lng) != (yj > lng);
      if (crossesLongitude) {
        // Calculate the latitude where the edge crosses the line of longitude 'lng'
        final double xIntersect = xi + (lng - yi) * (xj - xi) / (yj - yi);
        if (lat < xIntersect) {
          inside = !inside;
        }
      }
    }

    return inside;
  }

  /// Checks if point (lat, lng) lies directly on the segment between p1 and p2
  static bool _isPointOnSegment(
    double lat,
    double lng,
    List<double> p1,
    List<double> p2,
  ) {
    const double epsilon = 1e-6;
    final double minLat = min(p1[0], p2[0]) - epsilon;
    final double maxLat = max(p1[0], p2[0]) + epsilon;
    final double minLng = min(p1[1], p2[1]) - epsilon;
    final double maxLng = max(p1[1], p2[1]) + epsilon;

    if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) {
      return false;
    }

    // Cross product to test collinearity: (lat - p1.lat) * (p2.lng - p1.lng) - (lng - p1.lng) * (p2.lat - p1.lat)
    final double cross =
        (lat - p1[0]) * (p2[1] - p1[1]) - (lng - p1[1]) * (p2[0] - p1[0]);
    return cross.abs() < 1e-8;
  }

  /// Calculates Haversine distance in meters between two coordinates
  static double calculateDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final double dLat = (lat2 - lat1) * degToRad;
    final double dLng = (lng2 - lng1) * degToRad;

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * degToRad) *
            cos(lat2 * degToRad) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Calculates the shortest distance in meters from a point to the polygon boundary.
  /// If the point is inside the polygon, returns 0.0.
  static double distanceToPolygonMeters(
    double lat,
    double lng,
    List<List<double>> polygon,
  ) {
    if (polygon.isEmpty) return double.infinity;
    if (isPointInPolygon(lat, lng, polygon)) return 0.0;

    double minDistance = double.infinity;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final double dist = _distanceToSegmentMeters(
        lat,
        lng,
        polygon[j][0],
        polygon[j][1],
        polygon[i][0],
        polygon[i][1],
      );
      if (dist < minDistance) {
        minDistance = dist;
      }
    }
    return minDistance;
  }

  /// Calculates the distance from point (lat, lng) to the line segment (lat1, lng1) -> (lat2, lng2)
  static double _distanceToSegmentMeters(
    double lat,
    double lng,
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Project point onto line segment in equirectangular projection
    final double x = (lng - lng1) * cos((lat1 + lat2) / 2 * degToRad);
    final double y = lat - lat1;
    final double dx = (lng2 - lng1) * cos((lat1 + lat2) / 2 * degToRad);
    final double dy = lat2 - lat1;

    final double segLenSq = dx * dx + dy * dy;
    if (segLenSq == 0) {
      return calculateDistanceMeters(lat, lng, lat1, lng1);
    }

    final double t = max(0.0, min(1.0, (x * dx + y * dy) / segLenSq));
    final double projLat = lat1 + t * (lat2 - lat1);
    final double projLng = lng1 + t * (lng2 - lng1);

    return calculateDistanceMeters(lat, lng, projLat, projLng);
  }

  /// Computes the geographic centroid of a polygon
  static List<double> calculateCentroid(List<List<double>> polygon) {
    if (polygon.isEmpty) return [0.0, 0.0];
    if (polygon.length == 1) return [polygon[0][0], polygon[0][1]];

    double sumLat = 0.0;
    double sumLng = 0.0;
    for (final vertex in polygon) {
      sumLat += vertex[0];
      sumLng += vertex[1];
    }
    return [sumLat / polygon.length, sumLng / polygon.length];
  }

  /// Calculates spherical surface area of the polygon in square meters
  static double calculatePolygonAreaSquareMeters(List<List<double>> polygon) {
    if (polygon.length < 3) return 0.0;

    double total = 0.0;
    final int n = polygon.length;

    for (int i = 0; i < n; i++) {
      final int prev = (i - 1 + n) % n;
      final int next = (i + 1) % n;

      final double prevLng = polygon[prev][1] * degToRad;
      final double nextLng = polygon[next][1] * degToRad;
      final double currLat = polygon[i][0] * degToRad;

      total += (nextLng - prevLng) * sin(currLat);
    }

    total = (total.abs() * earthRadiusMeters * earthRadiusMeters) / 2.0;
    return total;
  }
}
