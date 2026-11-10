import 'package:equatable/equatable.dart';

class AttendanceRecord extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int durationSeconds;
  final String
  status; // 'Clocked In', 'On Break', 'Field Transit', 'Clocked Out'
  final bool isWithinGeofence;
  final double latitude;
  final double longitude;
  final double geofenceDistanceMeters;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.checkInTime,
    this.checkOutTime,
    required this.durationSeconds,
    required this.status,
    required this.isWithinGeofence,
    required this.latitude,
    required this.longitude,
    required this.geofenceDistanceMeters,
  });

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? durationSeconds,
    String? status,
    bool? isWithinGeofence,
    double? latitude,
    double? longitude,
    double? geofenceDistanceMeters,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      isWithinGeofence: isWithinGeofence ?? this.isWithinGeofence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      geofenceDistanceMeters:
          geofenceDistanceMeters ?? this.geofenceDistanceMeters,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    checkInTime,
    checkOutTime,
    durationSeconds,
    status,
    isWithinGeofence,
    latitude,
    longitude,
    geofenceDistanceMeters,
  ];
}
