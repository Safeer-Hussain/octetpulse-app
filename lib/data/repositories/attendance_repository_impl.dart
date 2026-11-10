import 'package:uuid/uuid.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/local/app_database.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  AttendanceRepositoryImpl(this._db);

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory() async {
    final db = await _db.database;
    final maps = await db.query('attendance', orderBy: 'checkInTime DESC');
    return maps.map((m) => _mapToAttendance(m)).toList();
  }

  @override
  Future<AttendanceRecord?> getLatestAttendanceRecord() async {
    final db = await _db.database;
    final maps = await db.query(
      'attendance',
      where: "employeeId = ?",
      whereArgs: ['EMP-101'],
      orderBy: 'checkInTime DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return _mapToAttendance(maps.first);
  }

  @override
  Future<AttendanceRecord> clockIn({
    required String employeeId,
    required String employeeName,
    required double latitude,
    required double longitude,
    required bool isWithinGeofence,
    required double geofenceDistanceMeters,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final record = AttendanceRecord(
      id: 'ATT-${_uuid.v4().substring(0, 8).toUpperCase()}',
      employeeId: employeeId,
      employeeName: employeeName,
      checkInTime: now,
      checkOutTime: null,
      durationSeconds: 0,
      status: 'Clocked In',
      isWithinGeofence: isWithinGeofence,
      latitude: latitude,
      longitude: longitude,
      geofenceDistanceMeters: geofenceDistanceMeters,
    );

    await db.insert('attendance', {
      'id': record.id,
      'employeeId': record.employeeId,
      'employeeName': record.employeeName,
      'checkInTime': record.checkInTime.toIso8601String(),
      'checkOutTime': null,
      'durationSeconds': 0,
      'status': record.status,
      'isWithinGeofence': record.isWithinGeofence ? 1 : 0,
      'latitude': record.latitude,
      'longitude': record.longitude,
      'geofenceDistanceMeters': record.geofenceDistanceMeters,
    });

    return record;
  }

  @override
  Future<AttendanceRecord> toggleBreak({required String recordId}) async {
    final db = await _db.database;
    final maps = await db.query('attendance', where: 'id = ?', whereArgs: [recordId]);
    if (maps.isEmpty) throw Exception('Attendance record not found');

    final current = _mapToAttendance(maps.first);
    final newStatus = current.status == 'On Break' ? 'Clocked In' : 'On Break';

    await db.update(
      'attendance',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [recordId],
    );

    return current.copyWith(status: newStatus);
  }

  @override
  Future<AttendanceRecord> clockOut({required String recordId}) async {
    final db = await _db.database;
    final maps = await db.query('attendance', where: 'id = ?', whereArgs: [recordId]);
    if (maps.isEmpty) throw Exception('Attendance record not found');

    final current = _mapToAttendance(maps.first);
    final now = DateTime.now();
    final duration = now.difference(current.checkInTime).inSeconds;

    await db.update(
      'attendance',
      {
        'checkOutTime': now.toIso8601String(),
        'status': 'Clocked Out',
        'durationSeconds': duration > 0 ? duration : current.durationSeconds,
      },
      where: 'id = ?',
      whereArgs: [recordId],
    );

    return current.copyWith(
      checkOutTime: now,
      status: 'Clocked Out',
      durationSeconds: duration > 0 ? duration : current.durationSeconds,
    );
  }

  @override
  Future<List<LeaveRequest>> getLeaveRequests() async {
    final db = await _db.database;
    final maps = await db.query('leave_requests', orderBy: 'submittedAt DESC');
    return maps.map((m) => _mapToLeaveRequest(m)).toList();
  }

  @override
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request) async {
    final db = await _db.database;
    await db.insert('leave_requests', {
      'id': request.id,
      'employeeId': request.employeeId,
      'employeeName': request.employeeName,
      'requestType': request.requestType,
      'hours': request.hours,
      'reason': request.reason,
      'submittedAt': request.submittedAt.toIso8601String(),
      'status': request.status,
      'approverComment': request.approverComment,
    });
    return request;
  }

  @override
  Future<LeaveRequest> updateLeaveRequestStatus({
    required String requestId,
    required String status,
    String? approverComment,
  }) async {
    final db = await _db.database;
    await db.update(
      'leave_requests',
      {
        'status': status,
        if (approverComment != null) 'approverComment': approverComment,
      },
      where: 'id = ?',
      whereArgs: [requestId],
    );

    final maps = await db.query('leave_requests', where: 'id = ?', whereArgs: [requestId]);
    return _mapToLeaveRequest(maps.first);
  }

  AttendanceRecord _mapToAttendance(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      checkInTime: DateTime.parse(map['checkInTime'] as String),
      checkOutTime: map['checkOutTime'] != null ? DateTime.parse(map['checkOutTime'] as String) : null,
      durationSeconds: map['durationSeconds'] as int,
      status: map['status'] as String,
      isWithinGeofence: (map['isWithinGeofence'] as int) == 1,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      geofenceDistanceMeters: (map['geofenceDistanceMeters'] as num).toDouble(),
    );
  }

  LeaveRequest _mapToLeaveRequest(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      requestType: map['requestType'] as String,
      hours: (map['hours'] as num).toDouble(),
      reason: map['reason'] as String,
      submittedAt: DateTime.parse(map['submittedAt'] as String),
      status: map['status'] as String,
      approverComment: map['approverComment'] as String?,
    );
  }
}
