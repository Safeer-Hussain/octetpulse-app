import '../../domain/entities/employee.dart';
import '../../domain/entities/voip_call_log.dart';
import '../../domain/entities/voip_telemetry.dart';
import '../../domain/repositories/voip_repository.dart';
import '../datasources/local/app_database.dart';
import '../datasources/native/voip_native_bridge.dart';

class VoipRepositoryImpl implements VoipRepository {
  final AppDatabase _db;
  final VoipNativeBridge _bridge;

  VoipRepositoryImpl(this._db, this._bridge);

  @override
  Future<List<Employee>> getDirectory() async {
    final db = await _db.database;
    final maps = await db.query('employees', orderBy: 'name ASC');
    return maps.map((m) {
      return Employee(
        id: m['id'] as String,
        name: m['name'] as String,
        email: m['email'] as String,
        department: m['department'] as String,
        role: m['role'] as String,
        avatarAsset: m['avatarAsset'] as String,
        baseSalaryUsd: (m['baseSalaryUsd'] as num).toDouble(),
        hourlyRateUsd: (m['hourlyRateUsd'] as num).toDouble(),
        presenceStatus: m['presenceStatus'] as String,
      );
    }).toList();
  }

  @override
  Future<List<VoipCallLog>> getCallLogs() async {
    final db = await _db.database;
    final maps = await db.query('voip_call_logs', orderBy: 'timestamp DESC');
    return maps.map((m) {
      return VoipCallLog(
        id: m['id'] as String,
        calleeId: m['calleeId'] as String,
        calleeName: m['calleeName'] as String,
        calleeRole: m['calleeRole'] as String,
        callType: m['callType'] as String,
        durationSeconds: m['durationSeconds'] as int,
        timestamp: DateTime.parse(m['timestamp'] as String),
        cipher: m['cipher'] as String,
        audioCodec: m['audioCodec'] as String,
        mosScore: (m['mosScore'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Stream<VoipTelemetry> getTelemetryStream() {
    return _bridge.telemetryStream;
  }

  @override
  Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String calleeName,
    String codec = 'OPUS-HD',
  }) {
    return _bridge.initiateCall(
      calleeId: calleeId,
      calleeName: calleeName,
      codec: codec,
    );
  }

  @override
  Future<Map<String, dynamic>> endCall() {
    return _bridge.endCall();
  }

  @override
  Future<bool> toggleMute({bool? forceState}) {
    return _bridge.toggleMute(forceState: forceState);
  }

  @override
  Future<bool> toggleSpeaker({bool? forceState}) {
    return _bridge.toggleSpeaker(forceState: forceState);
  }

  @override
  Future<void> logCompletedCall(VoipCallLog log) async {
    final db = await _db.database;
    await db.insert('voip_call_logs', {
      'id': log.id,
      'calleeId': log.calleeId,
      'calleeName': log.calleeName,
      'calleeRole': log.calleeRole,
      'callType': log.callType,
      'durationSeconds': log.durationSeconds,
      'timestamp': log.timestamp.toIso8601String(),
      'cipher': log.cipher,
      'audioCodec': log.audioCodec,
      'mosScore': log.mosScore,
    });
  }
}
