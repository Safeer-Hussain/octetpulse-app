import 'package:sqflite/sqflite.dart';

import '../../domain/entities/geofence_zone.dart';
import '../../domain/repositories/geofence_repository.dart';
import '../datasources/local/app_database.dart';

class GeofenceRepositoryImpl implements GeofenceRepository {
  final AppDatabase _db;

  GeofenceRepositoryImpl(this._db);

  @override
  Future<List<GeofenceZone>> getGeofenceZones() async {
    final db = await _db.database;
    final maps = await db.query(
      'geofence_zones',
      orderBy: 'isActive DESC, createdAt DESC',
    );
    return maps.map((m) => GeofenceZone.fromMap(m)).toList();
  }

  @override
  Future<GeofenceZone?> getActiveGeofenceZone() async {
    final db = await _db.database;
    final maps = await db.query(
      'geofence_zones',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return GeofenceZone.fromMap(maps.first);
  }

  @override
  Future<GeofenceZone> saveGeofenceZone(GeofenceZone zone) async {
    final db = await _db.database;

    if (zone.isActive) {
      // Deactivate other zones so only one primary campus boundary is active at a time
      await db.update('geofence_zones', {'isActive': 0});
    }

    await db.insert(
      'geofence_zones',
      zone.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return zone;
  }

  @override
  Future<void> deleteGeofenceZone(String zoneId) async {
    final db = await _db.database;
    await db.delete('geofence_zones', where: 'id = ?', whereArgs: [zoneId]);
  }

  @override
  Future<void> setActiveGeofenceZone(String zoneId) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('geofence_zones', {'isActive': 0});
      await txn.update(
        'geofence_zones',
        {'isActive': 1},
        where: 'id = ?',
        whereArgs: [zoneId],
      );
    });
  }
}
