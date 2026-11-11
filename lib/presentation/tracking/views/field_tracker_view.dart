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

  void _showSavePolygonDialog(BuildContext context, DispatchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final nameCtrl = TextEditingController(
      text: 'Campus Zone ${state.geofenceZones.length + 1}',
    );
    final descCtrl = TextEditingController(
      text:
          'Corporate facility boundary with ${state.draftPolygonVertices.length} perimeter vertices.',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Save Geofence Polygon Zone',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Define metadata for this ${state.draftPolygonVertices.length}-point perimeter boundary.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Campus Zone Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Zone Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final desc = descCtrl.text.trim();
              if (name.isNotEmpty) {
                context.read<DispatchBloc>().add(
                  SavePolygonZoneEvent(name: name, description: desc),
                );
              }
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Save Zone'),
          ),
        ],
      ),
    );
  }

  void _showZonesManagerModal(BuildContext context, DispatchState state) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (modalCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.layers, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Campus Geofence Zones (${state.geofenceZones.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(modalCtx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select an active polygon zone to enforce containment boundaries across workforce attendance and field tracking.',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.geofenceZones.length,
                  separatorBuilder: (_, _) =>
                      Divider(color: colorScheme.outlineVariant, height: 12),
                  itemBuilder: (ctx, idx) {
                    final zone = state.geofenceZones[idx];
                    final isActive = zone.id == state.activeGeofenceZone?.id;

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.25,
                              )
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      zone.name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${zone.vertices.length} vertices • ${(zone.areaSquareMeters / 10000).toStringAsFixed(2)} ha • ${zone.description}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!isActive)
                            FilledButton.tonal(
                              onPressed: () {
                                context.read<DispatchBloc>().add(
                                  SetActiveGeofenceZoneEvent(zoneId: zone.id),
                                );
                                Navigator.of(modalCtx).pop();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text('Set Active'),
                            ),
                          if (state.geofenceZones.length > 1)
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              onPressed: () {
                                context.read<DispatchBloc>().add(
                                  DeleteGeofenceZoneEvent(zoneId: zone.id),
                                );
                                Navigator.of(modalCtx).pop();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(modalCtx).pop();
                  context.read<DispatchBloc>().add(
                    const TogglePolygonEditorEvent(forceState: true),
                  );
                },
                icon: const Icon(Icons.edit_location_alt, size: 16),
                label: const Text('Draw New Campus Polygon'),
              ),
            ],
          ),
        ),
      ),
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
        SizedBox(height: 300, child: _buildMap(context, state)),
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
    final isEditor = state.isPolygonEditorActive;

    final markers = <Marker>[
      // HQ Center Marker
      Marker(
        point: const LatLng(AppConstants.hqLatitude, AppConstants.hqLongitude),
        width: 36,
        height: 36,
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
            size: 18,
          ),
        ),
      ),
    ];

    final polylines = <Polyline>[];
    final polygons = <Polygon>[];

    // Render configured geofence zones
    for (final zone in state.geofenceZones) {
      if (zone.vertices.length >= 3) {
        final isActive = zone.id == state.activeGeofenceZone?.id;
        final zonePoints = zone.vertices
            .map((v) => LatLng(v[0], v[1]))
            .toList();

        polygons.add(
          Polygon(
            points: zonePoints,
            color: isActive
                ? colorScheme.primary.withValues(alpha: 0.18)
                : colorScheme.outlineVariant.withValues(alpha: 0.08),
            borderColor: isActive ? colorScheme.primary : colorScheme.outline,
            borderStrokeWidth: isActive ? 2.5 : 1.2,
          ),
        );
      }
    }

    // Render draft polygon if editor is active
    if (isEditor && state.draftPolygonVertices.isNotEmpty) {
      final draftPoints = state.draftPolygonVertices
          .map((v) => LatLng(v[0], v[1]))
          .toList();

      // Connecting draft outline
      if (draftPoints.length >= 2) {
        polylines.add(
          Polyline(
            points: draftPoints,
            strokeWidth: 3.0,
            color: colorScheme.secondary,
          ),
        );
      }

      // Closed draft polygon preview
      if (draftPoints.length >= 3) {
        polygons.add(
          Polygon(
            points: draftPoints,
            color: colorScheme.secondary.withValues(alpha: 0.22),
            borderColor: colorScheme.secondary,
            borderStrokeWidth: 2.0,
          ),
        );
      }

      // Vertex anchor markers
      for (int i = 0; i < draftPoints.length; i++) {
        markers.add(
          Marker(
            point: draftPoints[i],
            width: 24,
            height: 24,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.onSecondary, width: 2),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    // Render fleet agent markers and routes
    for (final agent in state.agents) {
      final isSelected = state.selectedAgent?.id == agent.id;
      final isInside = state.isAgentInsideActiveGeofence(agent);

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
                    : (isInside
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? colorScheme.onSecondary
                      : (isInside ? colorScheme.primary : colorScheme.error),
                  width: 2.5,
                ),
              ),
              child: Icon(
                Icons.directions_car,
                size: 18,
                color: isSelected
                    ? colorScheme.onSecondary
                    : (isInside
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface),
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

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(
              AppConstants.hqLatitude,
              AppConstants.hqLongitude,
            ),
            initialZoom: 12.0,
            onTap: isEditor
                ? (_, point) {
                    context.read<DispatchBloc>().add(
                      AddPolygonVertexEvent(
                        latitude: point.latitude,
                        longitude: point.longitude,
                      ),
                    );
                  }
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.safeer.octetpulse',
            ),
            PolygonLayer(polygons: polygons),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),

        // Floating HUD Overlays
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: isEditor
              ? _buildEditorHud(context, state)
              : _buildStandardMapHud(context, state),
        ),
      ],
    );
  }

  Widget _buildStandardMapHud(BuildContext context, DispatchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final active = state.activeGeofenceZone;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.15),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    active != null
                        ? '${active.name} (${active.vertices.length}v)'
                        : 'Default Circular Geofence Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          tooltip: 'Manage Geofence Zones',
          onPressed: () => _showZonesManagerModal(context, state),
          icon: const Icon(Icons.layers, size: 18),
        ),
        const SizedBox(width: 4),
        FilledButton.icon(
          onPressed: () {
            context.read<DispatchBloc>().add(
              const TogglePolygonEditorEvent(forceState: true),
            );
          },
          icon: const Icon(Icons.edit_location_alt, size: 16),
          label: const Text('Draw Zone'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildEditorHud(BuildContext context, DispatchState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = state.draftPolygonVertices.length;
    final canSave = count >= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.secondary, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'POLYGON BOUNDARY EDITOR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: colorScheme.secondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count Vertices (Tap Map)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Undo Vertex',
            onPressed: count > 0
                ? () => context.read<DispatchBloc>().add(
                    const UndoPolygonVertexEvent(),
                  )
                : null,
            icon: const Icon(Icons.undo, size: 18),
          ),
          IconButton(
            tooltip: 'Clear Draft',
            onPressed: count > 0
                ? () => context.read<DispatchBloc>().add(
                    const ClearPolygonDraftEvent(),
                  )
                : null,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
          FilledButton.icon(
            onPressed: canSave
                ? () => _showSavePolygonDialog(context, state)
                : null,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Save'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
          const SizedBox(width: 2),
          IconButton(
            tooltip: 'Cancel Editor',
            onPressed: () => context.read<DispatchBloc>().add(
              const TogglePolygonEditorEvent(forceState: false),
            ),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentDetailCard(
    BuildContext context,
    FieldAgent agent,
    DispatchState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final task = state.selectedAgentTask;
    final isInside = state.isAgentInsideActiveGeofence(agent);

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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            agent.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isInside
                                  ? colorScheme.secondaryContainer
                                  : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isInside ? 'ON CAMPUS' : 'OFF SITE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isInside
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
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
                        'Task #${task.id}: ${task.title} (${task.priority})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openAssignModal(context, agent),
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text('Assign New Task'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(BuildContext context, String lbl, String val) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          lbl,
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
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
                final isInside = state.isAgentInsideActiveGeofence(agent);

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
                          backgroundColor: isInside
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.directions_car,
                            size: 16,
                            color: isInside
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    agent.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isInside
                                          ? colorScheme.secondaryContainer
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isInside ? 'CAMPUS' : 'TRANSIT',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: isInside
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
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
