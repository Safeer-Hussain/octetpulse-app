import 'package:equatable/equatable.dart';

class DispatchTask extends Equatable {
  final String id;
  final String agentId;
  final String agentName;
  final String title;
  final String clientName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String priority; // 'Critical', 'High', 'Standard'
  final String status; // 'In Transit', 'On Site', 'Resolved', 'Pending'
  final DateTime assignedAt;
  final DateTime slaDeadline;

  const DispatchTask({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.title,
    required this.clientName,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.status,
    required this.assignedAt,
    required this.slaDeadline,
  });

  DispatchTask copyWith({
    String? id,
    String? agentId,
    String? agentName,
    String? title,
    String? clientName,
    String? locationAddress,
    double? latitude,
    double? longitude,
    String? priority,
    String? status,
    DateTime? assignedAt,
    DateTime? slaDeadline,
  }) {
    return DispatchTask(
      id: id ?? this.id,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      title: title ?? this.title,
      clientName: clientName ?? this.clientName,
      locationAddress: locationAddress ?? this.locationAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      slaDeadline: slaDeadline ?? this.slaDeadline,
    );
  }

  @override
  List<Object?> get props => [
    id,
    agentId,
    agentName,
    title,
    clientName,
    locationAddress,
    latitude,
    longitude,
    priority,
    status,
    assignedAt,
    slaDeadline,
  ];
}
