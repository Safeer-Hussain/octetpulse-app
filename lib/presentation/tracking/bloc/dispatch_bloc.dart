import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/dispatch_task.dart';
import '../../../domain/entities/field_agent.dart';
import '../../../domain/repositories/dispatch_repository.dart';
import 'dispatch_event.dart';
import 'dispatch_state.dart';

class DispatchBloc extends Bloc<DispatchEvent, DispatchState> {
  final DispatchRepository _repository;
  final Uuid _uuid = const Uuid();
  Timer? _simulationTimer;

  DispatchBloc(this._repository) : super(const DispatchState()) {
    on<LoadDispatchData>(_onLoadDispatchData);
    on<ToggleSimulationEvent>(_onToggleSimulation);
    on<SimulationTickEvent>(_onSimulationTick);
    on<SelectFieldAgentEvent>(_onSelectFieldAgent);
    on<AssignNewTaskEvent>(_onAssignNewTask);
    on<UpdateTaskStatusEvent>(_onUpdateTaskStatus);
  }

  Future<void> _onLoadDispatchData(
    LoadDispatchData event,
    Emitter<DispatchState> emit,
  ) async {
    emit(state.copyWith(status: DispatchStatusState.loading));
    try {
      final agents = await _repository.getFieldAgents();
      final tasks = await _repository.getDispatchTasks();
      emit(
        state.copyWith(
          status: DispatchStatusState.loaded,
          agents: agents,
          tasks: tasks,
          selectedAgent: agents.isNotEmpty ? agents.first : null,
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
      final newSpeed = agent.speedKmh > 0 ? (28.0 + ((step * 7) % 35)) : 0.0;
      final newEta = agent.currentEtaMins > 0
          ? ((agent.currentEtaMins - 1).clamp(1, 45))
          : 0;

      await _repository.updateAgentLocation(agent.id, newLat, newLng, newSpeed);

      final updated = agent.copyWith(
        currentLat: newLat,
        currentLng: newLng,
        speedKmh: newSpeed,
        currentEtaMins: newEta,
      );
      updatedAgents.add(updated);
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
        simulationStep: step,
        selectedAgent: updatedSelected,
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

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    return super.close();
  }
}
