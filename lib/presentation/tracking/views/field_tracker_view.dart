import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../domain/entities/field_agent.dart';
import '../../voip/bloc/voip_bloc.dart';
import '../../voip/bloc/voip_event.dart';
import '../bloc/dispatch_bloc.dart';
import '../bloc/dispatch_event.dart';
import '../bloc/dispatch_state.dart';
import 'assign_dispatch_modal.dart';

class FieldTrackerView extends StatefulWidget {
  const FieldTrackerView({super.key});

  @override
  State<FieldTrackerView> createState() => _FieldTrackerViewState();
}

class _FieldTrackerViewState extends State<FieldTrackerView> {
  final MapController _mapController = MapController();

  void _openAssignModal(BuildContext context, FieldAgent agent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AssignDispatchModal(agent: agent),
    );
  }

  void _callAgent(BuildContext context, FieldAgent agent) {
    context.read<VoipBloc>().add(
      InitiateVoipCallEvent(
        calleeId: agent.id,
        calleeName: agent.name,
        calleeRole: agent.role,
      ),
    );
    AppFeedback.showInfo(
      context,
      'Launching encrypted VoIP bridge to ${agent.name}...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DispatchBloc, DispatchState>(
      listener: (context, state) {
        if (state.feedbackMessage != null) {
          AppFeedback.showSuccess(context, state.feedbackMessage!);
        }
        if (state.errorMessage != null) {
          AppFeedback.showError(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'fab_gps_dispatch',
            onPressed: () {
              context.read<DispatchBloc>().add(const ToggleSimulationEvent());
            },
            icon: Icon(
              state.isSimulatingMovement
                  ? Icons.pause_circle
                  : Icons.play_circle,
            ),
            label: Text(
              state.isSimulatingMovement
                  ? 'Pause Fleet Sim'
                  : 'Simulate Fleet Movement',
            ),
          ),
          body: isLandscape
              ? _buildLandscapeLayout(context, state)
              : _buildPortraitLayout(context, state),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BuildContext context, DispatchState state) {
    return Column(
      children: [
        SizedBox(height: 280, child: _buildMap(context, state)),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.selectedAgent != null) ...[
                  _buildAgentDetailCard(context, state.selectedAgent!, state),
                  const SizedBox(height: 16),
                ],
                _buildFleetList(context, state),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, DispatchState state) {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildMap(context, state)),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.selectedAgent != null) ...[
                  _buildAgentDetailCard(context, state.selectedAgent!, state),
                  const SizedBox(height: 12),
                ],
                _buildFleetList(context, state),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(BuildContext context, DispatchState state) {
    final colorScheme = Theme.of(context).colorScheme;

    final markers = <Marker>[
      // HQ Marker
      Marker(
        point: const LatLng(AppConstants.hqLatitude, AppConstants.hqLongitude),
        width: 38,
        height: 38,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.onPrimary, width: 2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.corporate_fare,
            color: colorScheme.onPrimary,
            size: 20,
          ),
        ),
      ),
    ];

    final polylines = <Polyline>[];

    for (final agent in state.agents) {
      final isSelected = state.selectedAgent?.id == agent.id;

      markers.add(
        Marker(
          point: LatLng(agent.currentLat, agent.currentLng),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () {
              context.read<DispatchBloc>().add(SelectFieldAgentEvent(agent));
              _mapController.move(
                LatLng(agent.currentLat, agent.currentLng),
                13.5,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.secondary
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.onSecondary
                      : colorScheme.primary,
                  width: 2.5,
                ),
              ),
              child: Icon(
                Icons.directions_car,
                size: 18,
                color: isSelected
                    ? colorScheme.onSecondary
                    : colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );

      if (agent.routeCoordinates.isNotEmpty) {
        final points = agent.routeCoordinates
            .map((c) => LatLng(c[0], c[1]))
            .toList();
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: isSelected ? 4.0 : 2.5,
            color: isSelected
                ? colorScheme.secondary
                : colorScheme.primary.withValues(alpha: 0.4),
          ),
        );
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(
          AppConstants.hqLatitude,
          AppConstants.hqLongitude,
        ),
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safeer.octetpulse',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildAgentDetailCard(
    BuildContext context,
    FieldAgent agent,
    DispatchState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = state.selectedAgentTask;

    return Card(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${agent.id} • ${agent.role}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _callAgent(context, agent),
                  icon: const Icon(Icons.call, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric(
                    context,
                    'Speed',
                    '${agent.speedKmh.toStringAsFixed(1)} km/h',
                  ),
                  _buildMetric(
                    context,
                    'Battery',
                    '${agent.batteryLevelPercent}%',
                  ),
                  _buildMetric(
                    context,
                    'ETA',
                    agent.currentEtaMins > 0
                        ? '${agent.currentEtaMins}m'
                        : 'On Site',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Destination: ${agent.destinationName}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            if (task != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Task: ${task.title} (${task.clientName})',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openAssignModal(context, agent),
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Assign Dispatch Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String label, String val) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildFleetList(BuildContext context, DispatchState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Field Units (${state.agents.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  state.isSimulatingMovement ? 'Live Moving' : 'Static GPS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: state.isSimulatingMovement
                        ? colorScheme.secondary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.agents.length,
              separatorBuilder: (_, _) =>
                  Divider(color: colorScheme.outlineVariant, height: 16),
              itemBuilder: (context, idx) {
                final agent = state.agents[idx];
                final isSelected = state.selectedAgent?.id == agent.id;

                return InkWell(
                  onTap: () {
                    context.read<DispatchBloc>().add(
                      SelectFieldAgentEvent(agent),
                    );
                    _mapController.move(
                      LatLng(agent.currentLat, agent.currentLng),
                      13.5,
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.directions_car,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agent.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                agent.destinationName,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${agent.speedKmh.toStringAsFixed(0)} km/h',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              agent.currentEtaMins > 0
                                  ? '${agent.currentEtaMins} min ETA'
                                  : 'On Site',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
