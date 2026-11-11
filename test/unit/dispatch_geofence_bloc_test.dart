import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/field_agent.dart';
import 'package:octet_pulse_app/domain/entities/geofence_zone.dart';
import 'package:octet_pulse_app/presentation/tracking/bloc/dispatch_bloc.dart';
import 'package:octet_pulse_app/presentation/tracking/bloc/dispatch_event.dart';
import 'package:octet_pulse_app/presentation/tracking/bloc/dispatch_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('DispatchBloc Geofence & Polygon Editor Tests', () {
    late FakeDispatchRepository dispatchRepo;
    late FakeGeofenceRepository geofenceRepo;

    final sampleZone = GeofenceZone(
      id: 'ZONE-ASTP-HQ',
      name: 'Arfa Software Technology Park Campus',
      description: 'Primary corporate campus perimeter.',
      vertices: const [
        [31.4770, 74.3418],
        [31.4772, 74.3455],
        [31.4738, 74.3460],
        [31.4735, 74.3422],
        [31.4750, 74.3415],
      ],
      isActive: true,
      createdAt: DateTime.now(),
    );

    final sampleAgentInside = const FieldAgent(
      id: 'AGT-01',
      name: 'Zeeshan Ali',
      department: 'Logistics',
      role: 'Fleet Lead',
      currentLat: 31.4754, // Inside ASTP
      currentLng: 74.3436,
      speedKmh: 42.0,
      batteryLevelPercent: 92,
      isOnline: true,
      currentEtaMins: 10,
      destinationName: 'Main Campus',
    );

    final sampleAgentOutside = const FieldAgent(
      id: 'AGT-02',
      name: 'Bilal Khan',
      department: 'Logistics',
      role: 'Field Dispatch',
      currentLat: 31.5200, // In Gulberg (outside ASTP)
      currentLng: 74.3520,
      speedKmh: 55.0,
      batteryLevelPercent: 78,
      isOnline: true,
      currentEtaMins: 25,
      destinationName: 'Gulberg Hub',
    );

    setUp(() {
      dispatchRepo = FakeDispatchRepository();
      geofenceRepo = FakeGeofenceRepository();
      geofenceRepo.zones = [sampleZone];
      dispatchRepo.agents = [sampleAgentInside, sampleAgentOutside];
    });

    blocTest<DispatchBloc, DispatchState>(
      'loads geofence zones from repository on LoadDispatchData',
      build: () => DispatchBloc(dispatchRepo, geofenceRepo),
      act: (bloc) => bloc.add(const LoadDispatchData()),
      verify: (bloc) {
        expect(bloc.state.status, DispatchStatusState.loaded);
        expect(bloc.state.geofenceZones.length, 1);
        expect(bloc.state.activeGeofenceZone?.id, 'ZONE-ASTP-HQ');
      },
    );

    blocTest<DispatchBloc, DispatchState>(
      'toggles polygon boundary editor state and resets draft vertices',
      build: () => DispatchBloc(dispatchRepo, geofenceRepo),
      act: (bloc) {
        bloc.add(const TogglePolygonEditorEvent(forceState: true));
        bloc.add(
          const AddPolygonVertexEvent(latitude: 31.48, longitude: 74.34),
        );
        bloc.add(const TogglePolygonEditorEvent(forceState: false));
      },
      verify: (bloc) {
        expect(bloc.state.isPolygonEditorActive, isFalse);
        expect(bloc.state.draftPolygonVertices, isEmpty);
      },
    );

    blocTest<DispatchBloc, DispatchState>(
      'adds, undoes, and clears polygon vertices during draft mode',
      build: () => DispatchBloc(dispatchRepo, geofenceRepo),
      seed: () => const DispatchState(isPolygonEditorActive: true),
      act: (bloc) {
        bloc.add(
          const AddPolygonVertexEvent(latitude: 31.477, longitude: 74.341),
        );
        bloc.add(
          const AddPolygonVertexEvent(latitude: 31.478, longitude: 74.342),
        );
        bloc.add(
          const AddPolygonVertexEvent(latitude: 31.479, longitude: 74.343),
        );
        bloc.add(const UndoPolygonVertexEvent()); // removes 3rd vertex
      },
      verify: (bloc) {
        expect(bloc.state.draftPolygonVertices.length, 2);
        expect(bloc.state.draftPolygonVertices.last, [31.478, 74.342]);
      },
    );

    blocTest<DispatchBloc, DispatchState>(
      'rejects saving polygon with fewer than 3 vertices',
      build: () => DispatchBloc(dispatchRepo, geofenceRepo),
      seed: () => const DispatchState(
        isPolygonEditorActive: true,
        draftPolygonVertices: [
          [31.477, 74.341],
          [31.478, 74.342],
        ],
      ),
      act: (bloc) => bloc.add(
        const SavePolygonZoneEvent(
          name: 'Invalid Zone',
          description: 'Only 2 vertices',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.errorMessage, contains('at least 3 vertices'));
      },
    );

    blocTest<DispatchBloc, DispatchState>(
      'saves valid polygon boundary to repository and sets it as active',
      build: () => DispatchBloc(dispatchRepo, geofenceRepo),
      seed: () => const DispatchState(
        isPolygonEditorActive: true,
        draftPolygonVertices: [
          [31.50, 74.30],
          [31.52, 74.30],
          [31.52, 74.33],
          [31.50, 74.33],
        ],
      ),
      act: (bloc) => bloc.add(
        const SavePolygonZoneEvent(
          name: 'DHA Technology Park',
          description: 'Custom DHA polygon perimeter',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.isPolygonEditorActive, isFalse);
        expect(bloc.state.draftPolygonVertices, isEmpty);
        expect(bloc.state.activeGeofenceZone?.name, 'DHA Technology Park');
        expect(bloc.state.geofenceZones.length, 2);
      },
    );

    test('isAgentInsideActiveGeofence correctly identifies on-campus and off-site units', () {
      final state = DispatchState(
        activeGeofenceZone: sampleZone,
        agents: [sampleAgentInside, sampleAgentOutside],
      );

      expect(state.isAgentInsideActiveGeofence(sampleAgentInside), isTrue);
      expect(state.isAgentInsideActiveGeofence(sampleAgentOutside), isFalse);
    });
  });
}
