import 'package:equatable/equatable.dart';
import '../../../domain/entities/field_agent.dart';

abstract class DispatchEvent extends Equatable {
  const DispatchEvent();

  @override
  List<Object?> get props => [];
}

class LoadDispatchData extends DispatchEvent {
  const LoadDispatchData();
}

class ToggleSimulationEvent extends DispatchEvent {
  const ToggleSimulationEvent();
}

class SimulationTickEvent extends DispatchEvent {
  const SimulationTickEvent();
}

class SelectFieldAgentEvent extends DispatchEvent {
  final FieldAgent? agent;

  const SelectFieldAgentEvent(this.agent);

  @override
  List<Object?> get props => [agent];
}

class AssignNewTaskEvent extends DispatchEvent {
  final String agentId;
  final String agentName;
  final String title;
  final String clientName;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final String priority;
  final DateTime slaDeadline;

  const AssignNewTaskEvent({
    required this.agentId,
    required this.agentName,
    required this.title,
    required this.clientName,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.slaDeadline,
  });

  @override
  List<Object?> get props => [
        agentId,
        agentName,
        title,
        clientName,
        locationAddress,
        latitude,
        longitude,
        priority,
        slaDeadline,
      ];
}

class UpdateTaskStatusEvent extends DispatchEvent {
  final String taskId;
  final String status;

  const UpdateTaskStatusEvent({required this.taskId, required this.status});

  @override
  List<Object?> get props => [taskId, status];
}
