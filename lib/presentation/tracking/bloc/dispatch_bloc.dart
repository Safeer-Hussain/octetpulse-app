import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/dispatch_task.dart';
import '../../../domain/entities/field_agent.dart';
import '../../../domain/entities/geofence_zone.dart';
import '../../../domain/repositories/dispatch_repository.dart';
import '../../../domain/repositories/geofence_repository.dart';
import 'dispatch_event.dart';
import 'dispatch_state.dart';

class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  final DispatchRepository _repository;
  final GeofenceRepository? _geofenceRepository;
  final Uuid _uuid = const Uuid();
  Timer? _simulationTimer;

  DispatchBloc(this._repository, [this._geofenceRepository])
    : super(const DispatchState()) {
    on<LoadDispatchData>(_onLoadDispatchData);
    on<ToggleSimulationEvent>(_onToggleSimulation);
    on<SimulationTickEvent>(_onSimulationTick);
    on<SelectFieldAgentEvent>(_onSelectFieldAgent);
    on<AssignNewTaskEvent>(_onAssignNewTask);
    on<UpdateTaskStatusEvent>(_onUpdateTaskStatus);
    on<TogglePolygonEditorEvent>(_onTogglePolygonEditor);
    on<AddPolygonVertexEvent>(_onAddPolygonVertex);
    on<UndoPolygonVertexEvent>(_onUndoPolygonVertex);
    on<ClearPolygonDraftEvent>(_onClearPolygonDraft);
    on<SavePolygonZoneEvent>(_onSavePolygonZone);
    on<SetActiveGeofenceZoneEvent>(_onSetActiveGeofenceZone);
    on<DeleteGeofenceZoneEvent>(_onDeleteGeofenceZone);
  }

  Future<void> _onLoadDispatchData(
    LoadDispatchData event,
    Emitter<DispatchState> emit,
  ) async {
    emit(state.copyWith(status: DispatchStatusState.loading));
    try {
      final agents = await _repository.getFieldAgents();
      final tasks = await _repository.getDispatchTasks();

      List<GeofenceZone> zones = [];
      GeofenceZone? activeZone;

      if (_geofenceRepository != null) {
        zones = await _geofenceRepository.getGeofenceZones();
        activeZone = await _geofenceRepository.getActiveGeofenceZone();
      }

      emit(
        state.copyWith(
          status: DispatchStatusState.loaded,
          agents: agents,
          tasks: tasks,
          selectedAgent: agents.isNotEmpty ? agents.first : null,
          geofenceZones: zones,
          activeGeofenceZone: activeZone,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DispatchStatusState.error,
          errorMessage: 'Failed to load fleet tracking data: $e',
        ),
      );
    }
  }

  void _onToggleSimulation(
    ToggleSimulationEvent event,
    Emitter<DispatchState> emit,
  ) {
    final next = !state.isSimulatingMovement;
    _simulationTimer?.cancel();

    if (next) {
      _simulationTimer = Timer.periodic(const Duration(milliseconds: 1800), (
        _,
      ) {
        add(const SimulationTickEvent());
      });
      emit(
        state.copyWith(
          isSimulatingMovement: true,
          feedbackMessage:
              'Live fleet movement simulation activated across Lahore nodes.',
        ),
      );
    } else {
      emit(
        state.copyWith(
          isSimulatingMovement: false,
          feedbackMessage: 'Fleet movement simulation paused.',
        ),
      );
    }
  }

  Future<void> _onSimulationTick(
    SimulationTickEvent event,
    Emitter<DispatchState> emit,
  ) async {
    if (!state.isSimulatingMovement || state.agents.isEmpty) return;

    final step = state.simulationStep + 1;
    final updatedAgents = <FieldAgent>[];

    for (final agent in state.agents) {
      if (agent.routeCoordinates.isEmpty) {
        updatedAgents.add(agent);
        continue;
      }
      final routeLen = agent.routeCoordinates.length;
      final idx = (step + state.agents.indexOf(agent)) % routeLen;
      final target = agent.routeCoordinates[idx];
      final newLat = target[0];
      final newLng = target[1];

      // Mutate location in DB asynchronously
      _repository.updateAgentLocation(agent.id, newLat, newLng, 38.5);

      final nextEta = agent.currentEtaMins > 0 ? agent.currentEtaMins - 1 : 15;
      final nextBattery = (agent.batteryLevelPercent - 1).clamp(10, 100);

      updatedAgents.add(
        agent.copyWith(
          currentLat: newLat,
          currentLng: newLng,
          currentEtaMins: nextEta,
          batteryLevelPercent: nextBattery,
        ),
      );
    }

    FieldAgent? updatedSelected = state.selectedAgent;
    if (updatedSelected != null) {
      final match = updatedAgents.where((a) => a.id == updatedSelected!.id);
      if (match.isNotEmpty) {
        updatedSelected = match.first;
      }
    }

    emit(
      state.copyWith(
        agents: updatedAgents,
        selectedAgent: updatedSelected,
        simulationStep: step,
      ),
    );
  }

  void _onSelectFieldAgent(
    SelectFieldAgentEvent event,
    Emitter<DispatchState> emit,
  ) {
    emit(state.copyWith(selectedAgent: event.agent));
  }

  Future<void> _onAssignNewTask(
    AssignNewTaskEvent event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      final task = DispatchTask(
        id: 'TSK-${_uuid.v4().substring(0, 6).toUpperCase()}',
        agentId: event.agentId,
        agentName: event.agentName,
        title: event.title,
        clientName: event.clientName,
        locationAddress: event.locationAddress,
        latitude: event.latitude,
        longitude: event.longitude,
        priority: event.priority,
        status: 'In Transit',
        assignedAt: DateTime.now(),
        slaDeadline: event.slaDeadline,
      );

      final saved = await _repository.assignTask(task);
      final updatedTasks = [saved, ...state.tasks];
      final updatedAgents = state.agents.map((a) {
        if (a.id == event.agentId) {
          return a.copyWith(activeTaskId: saved.id);
        }
        return a;
      }).toList();

      FieldAgent? updatedSelected = state.selectedAgent;
      if (updatedSelected?.id == event.agentId) {
        updatedSelected = updatedSelected?.copyWith(activeTaskId: saved.id);
      }

      emit(
        state.copyWith(
          tasks: updatedTasks,
          agents: updatedAgents,
          selectedAgent: updatedSelected,
          feedbackMessage: 'Task #${saved.id} assigned to ${saved.agentName}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Task assignment failed: $e'));
    }
  }

  Future<void> _onUpdateTaskStatus(
    UpdateTaskStatusEvent event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      final updated = await _repository.updateTaskStatus(
        event.taskId,
        event.status,
      );
      final updatedTasks = state.tasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList();

      emit(
        state.copyWith(
          tasks: updatedTasks,
          feedbackMessage: 'Task #${updated.id} marked ${updated.status}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Task update failed: $e'));
    }
  }

  void _onTogglePolygonEditor(
    TogglePolygonEditorEvent event,
    Emitter<DispatchState> emit,
  ) {
    final next = event.forceState ?? !state.isPolygonEditorActive;
    emit(
      state.copyWith(
        isPolygonEditorActive: next,
        draftPolygonVertices: next ? state.draftPolygonVertices : const [],
        feedbackMessage: next
            ? 'Geofence Polygon Boundary Editor enabled. Tap map to add vertices.'
            : 'Polygon Editor closed.',
      ),
    );
  }

  void _onAddPolygonVertex(
    AddPolygonVertexEvent event,
    Emitter<DispatchState> emit,
  ) {
    if (!state.isPolygonEditorActive) return;
    final updated = List<List<double>>.from(state.draftPolygonVertices);
    updated.add([event.latitude, event.longitude]);
    emit(state.copyWith(draftPolygonVertices: updated));
  }

  void _onUndoPolygonVertex(
    UndoPolygonVertexEvent event,
    Emitter<DispatchState> emit,
  ) {
    if (state.draftPolygonVertices.isEmpty) return;
    final updated = List<List<double>>.from(state.draftPolygonVertices);
    updated.removeLast();
    emit(state.copyWith(draftPolygonVertices: updated));
  }

  void _onClearPolygonDraft(
    ClearPolygonDraftEvent event,
    Emitter<DispatchState> emit,
  ) {
    emit(state.copyWith(draftPolygonVertices: const []));
  }

  Future<void> _onSavePolygonZone(
    SavePolygonZoneEvent event,
    Emitter<DispatchState> emit,
  ) async {
    if (state.draftPolygonVertices.length < 3) {
      emit(
        state.copyWith(
          errorMessage: 'Polygon boundary requires at least 3 vertices to enclose a campus zone.',
        ),
      );
      return;
    }

    try {
      final zoneId = 'ZONE-${_uuid.v4().substring(0, 8).toUpperCase()}';
      final newZone = GeofenceZone(
        id: zoneId,
        name: event.name,
        description: event.description,
        vertices: List<List<double>>.from(state.draftPolygonVertices),
        colorHex: event.colorHex,
        isActive: true,
        createdAt: DateTime.now(),
      );

      if (_geofenceRepository != null) {
        await _geofenceRepository.saveGeofenceZone(newZone);
        final allZones = await _geofenceRepository.getGeofenceZones();
        emit(
          state.copyWith(
            geofenceZones: allZones,
            activeGeofenceZone: newZone,
            isPolygonEditorActive: false,
            draftPolygonVertices: const [],
            feedbackMessage:
                'Geofence zone "${newZone.name}" saved and set as active.',
          ),
        );
      } else {
        final updatedZones = [
          newZone,
          ...state.geofenceZones.map((z) => z.copyWith(isActive: false)),
        ];
        emit(
          state.copyWith(
            geofenceZones: updatedZones,
            activeGeofenceZone: newZone,
            isPolygonEditorActive: false,
            draftPolygonVertices: const [],
            feedbackMessage:
                'Geofence zone "${newZone.name}" saved and set as active.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save polygon boundary: $e'));
    }
  }

  Future<void> _onSetActiveGeofenceZone(
    SetActiveGeofenceZoneEvent event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      if (_geofenceRepository != null) {
        await _geofenceRepository.setActiveGeofenceZone(event.zoneId);
        final allZones = await _geofenceRepository.getGeofenceZones();
        final active = allZones.firstWhere((z) => z.id == event.zoneId);
        emit(
          state.copyWith(
            geofenceZones: allZones,
            activeGeofenceZone: active,
            feedbackMessage:
                'Active campus geofence switched to ${active.name}.',
          ),
        );
      } else {
        final updated = state.geofenceZones.map((z) {
          return z.copyWith(isActive: z.id == event.zoneId);
        }).toList();
        final active = updated.firstWhere((z) => z.id == event.zoneId);
        emit(
          state.copyWith(
            geofenceZones: updated,
            activeGeofenceZone: active,
            feedbackMessage:
                'Active campus geofence switched to ${active.name}.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to switch active zone: $e'));
    }
  }

  Future<void> _onDeleteGeofenceZone(
    DeleteGeofenceZoneEvent event,
    Emitter<DispatchState> emit,
  ) async {
    try {
      if (_geofenceRepository != null) {
        await _geofenceRepository.deleteGeofenceZone(event.zoneId);
        final allZones = await _geofenceRepository.getGeofenceZones();
        final active = allZones.where((z) => z.isActive).isNotEmpty
            ? allZones.firstWhere((z) => z.isActive)
            : (allZones.isNotEmpty ? allZones.first : null);
        emit(
          state.copyWith(
            geofenceZones: allZones,
            activeGeofenceZone: active,
            clearActiveGeofenceZone: active == null,
            feedbackMessage: 'Geofence zone deleted.',
          ),
        );
      } else {
        final updated = state.geofenceZones
            .where((z) => z.id != event.zoneId)
            .toList();
        emit(
          state.copyWith(
            geofenceZones: updated,
            feedbackMessage: 'Geofence zone deleted.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete zone: $e'));
    }
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    return super.close();
  }
}
