import '../entities/attendance_record.dart';
import '../entities/leave_request.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> getAttendanceHistory();
  Future<AttendanceRecord?> getLatestAttendanceRecord();
  Future<AttendanceRecord> clockIn({
    required String employeeId,
    required String employeeName,
    required double latitude,
    required double longitude,
    required bool isWithinGeofence,
    required double geofenceDistanceMeters,
  });
  Future<AttendanceRecord> toggleBreak({required String recordId});
  Future<AttendanceRecord> clockOut({required String recordId});
  Future<List<LeaveRequest>> getLeaveRequests();
  Future<LeaveRequest> submitLeaveRequest(LeaveRequest request);
  Future<LeaveRequest> updateLeaveRequestStatus({
    required String requestId,
    required String status,
    String? approverComment,
  });
}
