import 'package:equatable/equatable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/attendance_record.dart';
import '../../../domain/entities/leave_request.dart';

enum AttendanceStatusState { initial, loading, loaded, error }

class AttendanceState extends Equatable {
  final AttendanceStatusState status;
  final AttendanceRecord? currentRecord;
  final List<AttendanceRecord> history;
  final List<LeaveRequest> leaveRequests;
  final double currentLatitude;
  final double currentLongitude;
  final bool isWithinGeofence;
  final double geofenceDistanceMeters;
  final String? errorMessage;
  final String? feedbackMessage;

  const AttendanceState({
    this.status = AttendanceStatusState.initial,
    this.currentRecord,
    this.history = const [],
    this.leaveRequests = const [],
    this.currentLatitude = AppConstants.hqLatitude,
    this.currentLongitude = AppConstants.hqLongitude,
    this.isWithinGeofence = true,
    this.geofenceDistanceMeters = 24.5,
    this.errorMessage,
    this.feedbackMessage,
  });

  bool get isClockedIn =>
      currentRecord != null && currentRecord!.status == 'Clocked In';
  bool get isOnBreak =>
      currentRecord != null && currentRecord!.status == 'On Break';

  List<LeaveRequest> get pendingLeaveRequests =>
      leaveRequests.where((req) => req.status == 'Pending').toList();

  AttendanceState copyWith({
    AttendanceStatusState? status,
    AttendanceRecord? currentRecord,
    bool clearCurrentRecord = false,
    List<AttendanceRecord>? history,
    List<LeaveRequest>? leaveRequests,
    double? currentLatitude,
    double? currentLongitude,
    bool? isWithinGeofence,
    double? geofenceDistanceMeters,
    String? errorMessage,
    String? feedbackMessage,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      currentRecord: clearCurrentRecord
          ? null
          : (currentRecord ?? this.currentRecord),
      history: history ?? this.history,
      leaveRequests: leaveRequests ?? this.leaveRequests,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      geofenceDistanceMeters:
          geofenceDistanceMeters ?? this.geofenceDistanceMeters,
      errorMessage: errorMessage,
      feedbackMessage: feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentRecord,
    history,
    leaveRequests,
    currentLatitude,
    currentLongitude,
    isWithinGeofence,
    geofenceDistanceMeters,
    errorMessage,
    feedbackMessage,
  ];
}
