import 'package:equatable/equatable.dart';

import '../../../domain/entities/dispatch_task.dart';
import '../../../domain/entities/field_agent.dart';
import '../../../domain/entities/geofence_zone.dart';

enum DispatchStatusState { initial, loading, loaded, error }

class DispatchState extends Equatable {
  final DispatchStatusState status;
  final List<FieldAgent> agents;
  final List<DispatchTask> tasks;
  final FieldAgent? selectedAgent;
  final bool isSimulatingMovement;
  final int simulationStep;
  final List<GeofenceZone> geofenceZones;
  final GeofenceZone? activeGeofenceZone;
  final bool isPolygonEditorActive;
  final List<List<double>> draftPolygonVertices;
  final String? feedbackMessage;
  final String? errorMessage;

  const DispatchState({
    this.status = DispatchStatusState.initial,
    this.agents = const [],
    this.tasks = const [],
    this.selectedAgent,
    this.isSimulatingMovement = false,
    this.simulationStep = 0,
    this.geofenceZones = const [],
    this.activeGeofenceZone,
    this.isPolygonEditorActive = false,
    this.draftPolygonVertices = const [],
    this.feedbackMessage,
    this.errorMessage,
  });

  DispatchTask? get selectedAgentTask {
    if (selectedAgent == null || selectedAgent!.activeTaskId == null) {
      return null;
    }
    try {
      return tasks.firstWhere((t) => t.id == selectedAgent!.activeTaskId);
    } catch (_) {
      return null;
    }
  }

  bool isAgentInsideActiveGeofence(FieldAgent agent) {
    if (activeGeofenceZone == null || activeGeofenceZone!.vertices.length < 3) {
      return true;
    }
    return activeGeofenceZone!.containsPoint(
      agent.currentLat,
      agent.currentLng,
    );
  }

  DispatchState copyWith({
    DispatchStatusState? status,
    List<FieldAgent>? agents,
    List<DispatchTask>? tasks,
    FieldAgent? selectedAgent,
    bool clearSelectedAgent = false,
    bool? isSimulatingMovement,
    int? simulationStep,
    List<GeofenceZone>? geofenceZones,
    GeofenceZone? activeGeofenceZone,
    bool clearActiveGeofenceZone = false,
    bool? isPolygonEditorActive,
    List<List<double>>? draftPolygonVertices,
    String? feedbackMessage,
    String? errorMessage,
  }) {
    return DispatchState(
      status: status ?? this.status,
      agents: agents ?? this.agents,
      tasks: tasks ?? this.tasks,
      selectedAgent: clearSelectedAgent
          ? null
          : (selectedAgent ?? this.selectedAgent),
      isSimulatingMovement: isSimulatingMovement ?? this.isSimulatingMovement,
      simulationStep: simulationStep ?? this.simulationStep,
      geofenceZones: geofenceZones ?? this.geofenceZones,
      activeGeofenceZone: clearActiveGeofenceZone
          ? null
          : (activeGeofenceZone ?? this.activeGeofenceZone),
      isPolygonEditorActive:
          isPolygonEditorActive ?? this.isPolygonEditorActive,
      draftPolygonVertices: draftPolygonVertices ?? this.draftPolygonVertices,
      feedbackMessage: feedbackMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    agents,
    tasks,
    selectedAgent,
    isSimulatingMovement,
    simulationStep,
    geofenceZones,
    activeGeofenceZone,
    isPolygonEditorActive,
    draftPolygonVertices,
    feedbackMessage,
    errorMessage,
  ];
}
