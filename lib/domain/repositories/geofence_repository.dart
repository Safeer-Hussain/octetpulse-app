import '../entities/geofence_zone.dart';

abstract class GeofenceRepository {
  Future<List<GeofenceZone>> getGeofenceZones();
  Future<GeofenceZone?> getActiveGeofenceZone();
  Future<GeofenceZone> saveGeofenceZone(GeofenceZone zone);
  Future<void> deleteGeofenceZone(String zoneId);
  Future<void> setActiveGeofenceZone(String zoneId);
}
