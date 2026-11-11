import 'dart:async';

import 'package:octet_pulse_app/domain/entities/attendance_record.dart';
import 'package:octet_pulse_app/domain/entities/dispatch_task.dart';
import 'package:octet_pulse_app/domain/entities/employee.dart';
import 'package:octet_pulse_app/domain/entities/field_agent.dart';
import 'package:octet_pulse_app/domain/entities/geofence_zone.dart';
import 'package:octet_pulse_app/domain/entities/leave_request.dart';
import 'package:octet_pulse_app/domain/entities/payroll_record.dart';
import 'package:octet_pulse_app/domain/entities/voip_call_log.dart';
import 'package:octet_pulse_app/domain/entities/voip_recording.dart';
import 'package:octet_pulse_app/domain/entities/voip_telemetry.dart';
import 'package:octet_pulse_app/domain/repositories/attendance_repository.dart';
import 'package:octet_pulse_app/domain/repositories/dispatch_repository.dart';
import 'package:octet_pulse_app/domain/repositories/geofence_repository.dart';
import 'package:octet_pulse_app/domain/repositories/payroll_repository.dart';
import 'package:octet_pulse_app/domain/repositories/voip_repository.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  List<AttendanceRecord> records = [];
  List<LeaveRequest> leaveRequests = [];

  @override
  Future<List<AttendanceRecord>> getAttendanceHistory() async => records;

  @override
  Future<AttendanceRecord?> getLatestAttendanceRecord() async =>
      records.isNotEmpty ? records.first : null;

  @override
  Future<AttendanceRecord> clockIn({
    required String employeeId,
    required String employeeName,
    required double latitude,
    required double longitude,
    required bool isWithinGeofence,
    required double geofenceDistanceMeters,
  }) async {
    final record = AttendanceRecord(
      id: 'ATT-TEST-1',
      employeeId: employeeId,
      employeeName: employeeName,
      checkInTime: DateTime.now(),
      durationSeconds: 0,
      status: 'Clocked In',
      isWithinGeofence: isWithinGeofence,
      latitude: latitude,
      longitude: longitude,
      geofenceDistanceMeters: geofenceDistanceMeters,
    );
    records.insert(0, record);
    return record;
  }

  @override
  Future<AttendanceRecord> toggleBreak({required String recordId}) async {
    final idx = records.indexWhere((r) => r.id == recordId);
    final current = records[idx];
    final updated = current.copyWith(
      status: current.status == 'On Break' ? 'Clocked In' : 'On Break',
    );
    records[idx] = updated;
    return updated;
  }

  @override
  Future<AttendanceRecord> clockOut({required String recordId}) async {
    final idx = records.indexWhere((r) => r.id == recordId);
    final current = records[idx];
    final updated = current.copyWith(
      checkOutTime: DateTime.now(),
      status: 'Clocked Out',
    );
    records[idx] = updated;
    return updated;
  }

  @override
  Future<List<LeaveRequest>> getLeaveRequests() async => leaveRequests;

  @override
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request) async {
    leaveRequests.insert(0, request);
    return request;
  }

  @override
  Future<LeaveRequest> updateLeaveRequestStatus({
    required String requestId,
    required String status,
    String? approverComment,
  }) async {
    final idx = leaveRequests.indexWhere((r) => r.id == requestId);
    final current = leaveRequests[idx];
    final updated = current.copyWith(
      status: status,
      approverComment: approverComment,
    );
    leaveRequests[idx] = updated;
    return updated;
  }
}

class FakePayrollRepository implements PayrollRepository {
  List<PayrollRecord> records = [];

  @override
  Future<List<PayrollRecord>> getPayrollRecords() async => records;

  @override
  Future<void> runPayrollBatch({required String monthYear}) async {
    for (int i = 0; i < records.length; i++) {
      records[i] = records[i].copyWith(monthYear: monthYear, status: 'Pending');
    }
  }

  @override
  Future<PayrollRecord> disbursePayroll({required String recordId}) async {
    final idx = records.indexWhere((r) => r.id == recordId);
    final current = records[idx];
    final updated = current.copyWith(
      status: 'Disbursed',
      disbursedAt: DateTime.now(),
    );
    records[idx] = updated;
    return updated;
  }

  @override
  Future<PayrollRecord> recalculatePayrollRecord(PayrollRecord record) async =>
      record;
}

class FakeVoipRepository implements VoipRepository {
  final StreamController<VoipTelemetry> _telemetryCtrl =
      StreamController<VoipTelemetry>.broadcast();
  List<Employee> directory = [];
  List<VoipCallLog> logs = [];
  List<VoipRecording> recordings = [];
  bool isRecordingActive = false;

  @override
  Future<List<Employee>> getDirectory() async => directory;

  @override
  Future<List<VoipCallLog>> getCallLogs() async => logs;

  @override
  Stream<VoipTelemetry> getTelemetryStream() => _telemetryCtrl.stream;

  void emitTelemetry(VoipTelemetry telemetry) => _telemetryCtrl.add(telemetry);

  @override
  Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String calleeName,
    String codec = 'OPUS-HD',
  }) async {
    return {
      'status': 'initiated',
      'callId': 'call_fake_123',
      'calleeId': calleeId,
      'calleeName': calleeName,
      'cipher': 'SRTP-AES256',
      'codec': codec,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<Map<String, dynamic>> endCall() async {
    return {
      'status': 'terminated',
      'callId': 'call_fake_123',
      'durationSeconds': 120,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<bool> toggleMute({bool? forceState}) async => forceState ?? true;

  @override
  Future<bool> toggleSpeaker({bool? forceState}) async => forceState ?? true;

  @override
  Future<void> logCompletedCall(VoipCallLog log) async => logs.insert(0, log);

  @override
  Future<List<VoipRecording>> getRecordings() async => recordings;

  @override
  Future<void> saveRecording(VoipRecording recording) async {
    final idx = recordings.indexWhere((r) => r.id == recording.id);
    if (idx >= 0) {
      recordings[idx] = recording;
    } else {
      recordings.insert(0, recording);
    }
  }

  @override
  Future<void> deleteRecording(String recordingId) async {
    recordings.removeWhere((r) => r.id == recordingId);
  }

  @override
  Future<Map<String, dynamic>> startRecording({required String callId}) async {
    isRecordingActive = true;
    return {
      'status': 'recording_active',
      'callId': callId,
      'cipher': 'AES-256-GCM',
      'isRecording': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<Map<String, dynamic>> stopRecording() async {
    isRecordingActive = false;
    return {
      'status': 'recording_stopped',
      'isRecording': false,
      'cipher': 'AES-256-GCM',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  @override
  Future<bool> toggleRecording({bool? forceState}) async {
    isRecordingActive = forceState ?? !isRecordingActive;
    return isRecordingActive;
  }
}

class FakeDispatchRepository implements DispatchRepository {
  List<FieldAgent> agents = [];
  List<DispatchTask> tasks = [];

  @override
  Future<List<FieldAgent>> getFieldAgents() async => agents;

  @override
  Future<List<DispatchTask>> getDispatchTasks() async => tasks;

  @override
  Future<void> updateAgentLocation(
    String agentId,
    double lat,
    double lng,
    double speed,
  ) async {}

  @override
  Future<DispatchTask> assignTask(DispatchTask task) async {
    tasks.insert(0, task);
    return task;
  }

  @override
  Future<DispatchTask> updateTaskStatus(String taskId, String status) async {
    final idx = tasks.indexWhere((t) => t.id == taskId);
    final updated = tasks[idx].copyWith(status: status);
    tasks[idx] = updated;
    return updated;
  }
}

class FakeGeofenceRepository implements GeofenceRepository {
  List<GeofenceZone> zones = [];

  @override
  Future<List<GeofenceZone>> getGeofenceZones() async => zones;

  @override
  Future<GeofenceZone?> getActiveGeofenceZone() async {
    final matches = zones.where((z) => z.isActive);
    return matches.isNotEmpty
        ? matches.first
        : (zones.isNotEmpty ? zones.first : null);
  }

  @override
  Future<GeofenceZone> saveGeofenceZone(GeofenceZone zone) async {
    if (zone.isActive) {
      zones = zones.map((z) => z.copyWith(isActive: false)).toList();
    }
    final idx = zones.indexWhere((z) => z.id == zone.id);
    if (idx >= 0) {
      zones[idx] = zone;
    } else {
      zones.insert(0, zone);
    }
    return zone;
  }

  @override
  Future<void> deleteGeofenceZone(String zoneId) async {
    zones.removeWhere((z) => z.id == zoneId);
  }

  @override
  Future<void> setActiveGeofenceZone(String zoneId) async {
    zones = zones.map((z) => z.copyWith(isActive: z.id == zoneId)).toList();
  }
}
