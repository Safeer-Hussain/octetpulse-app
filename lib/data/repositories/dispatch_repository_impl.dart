import 'dart:convert';
import '../../domain/entities/dispatch_task.dart';
import '../../domain/entities/field_agent.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../datasources/local/app_database.dart';

class DispatchRepositoryImpl implements DispatchRepository {
  final AppDatabase _db;

  DispatchRepositoryImpl(this._db);

  @override
  Future<List<FieldAgent>> getFieldAgents() async {
    final db = await _db.database;
    final maps = await db.query('field_agents');
    return maps.map((m) => _mapToFieldAgent(m)).toList();
  }

  @override
  Future<List<DispatchTask>> getDispatchTasks() async {
    final db = await _db.database;
    final maps = await db.query('dispatch_tasks', orderBy: 'assignedAt DESC');
    return maps.map((m) => _mapToDispatchTask(m)).toList();
  }

  @override
  Future<void> updateAgentLocation(String agentId, double lat, double lng, double speed) async {
    final db = await _db.database;
    await db.update(
      'field_agents',
      {
        'currentLat': lat,
        'currentLng': lng,
        'speedKmh': speed,
      },
      where: 'id = ?',
      whereArgs: [agentId],
    );
  }

  @override
  Future<DispatchTask> assignTask(DispatchTask task) async {
    final db = await _db.database;
    await db.insert('dispatch_tasks', {
      'id': task.id,
      'agentId': task.agentId,
      'agentName': task.agentName,
      'title': task.title,
      'clientName': task.clientName,
      'locationAddress': task.locationAddress,
      'latitude': task.latitude,
      'longitude': task.longitude,
      'priority': task.priority,
      'status': task.status,
      'assignedAt': task.assignedAt.toIso8601String(),
      'slaDeadline': task.slaDeadline.toIso8601String(),
    });

    await db.update(
      'field_agents',
      {'activeTaskId': task.id},
      where: 'id = ?',
      whereArgs: [task.agentId],
    );

    return task;
  }

  @override
  Future<DispatchTask> updateTaskStatus(String taskId, String status) async {
    final db = await _db.database;
    await db.update(
      'dispatch_tasks',
      {'status': status},
      where: 'id = ?',
      whereArgs: [taskId],
    );
    final maps = await db.query('dispatch_tasks', where: 'id = ?', whereArgs: [taskId]);
    return _mapToDispatchTask(maps.first);
  }

  FieldAgent _mapToFieldAgent(Map<String, dynamic> map) {
    final rawCoords = jsonDecode(map['routeCoordinates'] as String) as List<dynamic>;
    final coords = rawCoords.map((e) => (e as List<dynamic>).map((c) => (c as num).toDouble()).toList()).toList();

    return FieldAgent(
      id: map['id'] as String,
      name: map['name'] as String,
      department: map['department'] as String,
      role: map['role'] as String,
      currentLat: (map['currentLat'] as num).toDouble(),
      currentLng: (map['currentLng'] as num).toDouble(),
      speedKmh: (map['speedKmh'] as num).toDouble(),
      batteryLevelPercent: map['batteryLevelPercent'] as int,
      isOnline: (map['isOnline'] as int) == 1,
      currentEtaMins: map['currentEtaMins'] as int,
      destinationName: map['destinationName'] as String,
      activeTaskId: map['activeTaskId'] as String?,
      routeCoordinates: coords,
    );
  }

  DispatchTask _mapToDispatchTask(Map<String, dynamic> map) {
    return DispatchTask(
      id: map['id'] as String,
      agentId: map['agentId'] as String,
      agentName: map['agentName'] as String,
      title: map['title'] as String,
      clientName: map['clientName'] as String,
      locationAddress: map['locationAddress'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      priority: map['priority'] as String,
      status: map['status'] as String,
      assignedAt: DateTime.parse(map['assignedAt'] as String),
      slaDeadline: DateTime.parse(map['slaDeadline'] as String),
    );
  }
}
