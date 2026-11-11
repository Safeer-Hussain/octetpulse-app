import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/services/geofence_engine.dart';

void main() {
  group('GeofenceEngine Ray-Casting Point-in-Polygon (PIP) Tests', () {
    // Convex polygon around ASTP Lahore:
    // NW: [31.4770, 74.3418]
    // NE: [31.4772, 74.3455]
    // SE: [31.4738, 74.3460]
    // SW: [31.4735, 74.3422]
    // W:  [31.4750, 74.3415]
    final astpPolygon = [
      [31.4770, 74.3418],
      [31.4772, 74.3455],
      [31.4738, 74.3460],
      [31.4735, 74.3422],
      [31.4750, 74.3415],
    ];

    test('returns true for coordinates strictly inside the polygon', () {
      // HQ Center: [31.4754, 74.3436] is inside
      const insideLat = 31.4754;
      const insideLng = 74.3436;

      final isInside = GeofenceEngine.isPointInPolygon(
        insideLat,
        insideLng,
        astpPolygon,
      );
      expect(isInside, isTrue);
    });

    test('returns false for coordinates clearly outside the polygon', () {
      // Point 500m north: [31.4850, 74.3436]
      const outsideLatNorth = 31.4850;
      const outsideLngNorth = 74.3436;

      expect(
        GeofenceEngine.isPointInPolygon(
          outsideLatNorth,
          outsideLngNorth,
          astpPolygon,
        ),
        isFalse,
      );

      // Point in Gulberg (several km north): [31.5200, 74.3520]
      expect(
        GeofenceEngine.isPointInPolygon(31.5200, 74.3520, astpPolygon),
        isFalse,
      );
    });

    test('returns true for a point lying on a polygon vertex', () {
      final vertexLat = astpPolygon[0][0];
      final vertexLng = astpPolygon[0][1];

      final isOnVertex = GeofenceEngine.isPointInPolygon(
        vertexLat,
        vertexLng,
        astpPolygon,
      );
      expect(isOnVertex, isTrue);
    });

    test('returns false for degenerate polygons with less than 3 vertices', () {
      final lineSegment = [
        [31.4770, 74.3418],
        [31.4772, 74.3455],
      ];
      expect(
        GeofenceEngine.isPointInPolygon(31.4771, 74.3430, lineSegment),
        isFalse,
      );

      expect(GeofenceEngine.isPointInPolygon(31.4770, 74.3418, []), isFalse);
    });

    test('handles concave L-shaped polygon boundaries correctly', () {
      // L-shaped polygon:
      // (0,0) -> (4,0) -> (4,2) -> (2,2) -> (2,4) -> (0,4)
      final lShape = [
        [0.0, 0.0],
        [4.0, 0.0],
        [4.0, 2.0],
        [2.0, 2.0],
        [2.0, 4.0],
        [0.0, 4.0],
      ];

      // Inside the bottom branch: (1, 1)
      expect(GeofenceEngine.isPointInPolygon(1.0, 1.0, lShape), isTrue);

      // Inside the corner: (1, 3)
      expect(GeofenceEngine.isPointInPolygon(1.0, 3.0, lShape), isTrue);

      // Outside the cut-out corner: (3, 3)
      expect(GeofenceEngine.isPointInPolygon(3.0, 3.0, lShape), isFalse);

      // Far outside: (5, 5)
      expect(GeofenceEngine.isPointInPolygon(5.0, 5.0, lShape), isFalse);
    });

    test('calculates Haversine distance in meters accurately', () {
      // Distance from ASTP [31.4754, 74.3436] to Gulberg [31.5200, 74.3520] is ~5 km
      final dist = GeofenceEngine.calculateDistanceMeters(
        31.4754,
        74.3436,
        31.5200,
        74.3520,
      );
      expect(dist, greaterThan(4500));
      expect(dist, lessThan(5500));
    });

    test('distance to polygon returns 0.0 when inside', () {
      final dist = GeofenceEngine.distanceToPolygonMeters(
        31.4754,
        74.3436,
        astpPolygon,
      );
      expect(dist, 0.0);
    });

    test('distance to polygon returns positive meters when outside', () {
      final dist = GeofenceEngine.distanceToPolygonMeters(
        31.4850,
        74.3436,
        astpPolygon,
      );
      expect(dist, greaterThan(500.0));
    });

    test('calculates centroid coordinates', () {
      final centroid = GeofenceEngine.calculateCentroid(astpPolygon);
      expect(centroid[0], closeTo(31.4753, 0.005));
      expect(centroid[1], closeTo(74.3434, 0.005));
    });

    test('calculates polygon surface area in square meters', () {
      final area = GeofenceEngine.calculatePolygonAreaSquareMeters(astpPolygon);
      // Campus perimeter is several hectares (~100,000 m2)
      expect(area, greaterThan(50000));
      expect(area, lessThan(500000));
    });
  });
}
