import '../entities/employee.dart';
import '../entities/voip_call_log.dart';
import '../entities/voip_telemetry.dart';

abstract class VoipRepository {
  Future<List<Employee>> getDirectory();
  Future<List<VoipCallLog>> getCallLogs();
  Stream<VoipTelemetry> getTelemetryStream();
  Future<Map<String, dynamic>> initiateCall({
    required String calleeId,
    required String calleeName,
    String codec = 'OPUS-HD',
  });
  Future<Map<String, dynamic>> endCall();
  Future<bool> toggleMute({bool? forceState});
  Future<bool> toggleSpeaker({bool? forceState});
  Future<void> logCompletedCall(VoipCallLog log);
}
