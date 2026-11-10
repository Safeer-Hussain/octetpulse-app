import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadAttendanceData extends AttendanceEvent {
  const LoadAttendanceData();
}

class ClockInEvent extends AttendanceEvent {
  final String employeeId;
  final String employeeName;
  final double latitude;
  final double longitude;
  final bool isWithinGeofence;
  final double geofenceDistanceMeters;

  const ClockInEvent({
    required this.employeeId,
    required this.employeeName,
    required this.latitude,
    required this.longitude,
    required this.isWithinGeofence,
    required this.geofenceDistanceMeters,
  });

  @override
  List<Object?> get props => [
        employeeId,
        employeeName,
        latitude,
        longitude,
        isWithinGeofence,
        geofenceDistanceMeters,
      ];
}

class ToggleBreakEvent extends AttendanceEvent {
  const ToggleBreakEvent();
}

class ClockOutEvent extends AttendanceEvent {
  const ClockOutEvent();
}

class SubmitLeaveRequestEvent extends AttendanceEvent {
  final String employeeId;
  final String employeeName;
  final String requestType;
  final double hours;
  final String reason;

  const SubmitLeaveRequestEvent({
    required this.employeeId,
    required this.employeeName,
    required this.requestType,
    required this.hours,
    required this.reason,
  });

  @override
  List<Object?> get props => [employeeId, employeeName, requestType, hours, reason];
}

class ApproveLeaveRequestEvent extends AttendanceEvent {
  final String requestId;
  final String status;
  final String? comment;

  const ApproveLeaveRequestEvent({
    required this.requestId,
    required this.status,
    this.comment,
  });

  @override
  List<Object?> get props => [requestId, status, comment];
}

class UpdateGeofencePositionEvent extends AttendanceEvent {
  final double latitude;
  final double longitude;

  const UpdateGeofencePositionEvent({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}
