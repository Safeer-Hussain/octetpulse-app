import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/theme/app_theme.dart';
import 'package:octet_pulse_app/domain/entities/field_agent.dart';
import 'package:octet_pulse_app/domain/entities/geofence_zone.dart';
import 'package:octet_pulse_app/presentation/tracking/bloc/dispatch_bloc.dart';
import 'package:octet_pulse_app/presentation/tracking/views/field_tracker_view.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_bloc.dart';

import '../fakes/fake_repositories.dart';

void main() {
  final sampleZone = GeofenceZone(
    id: 'ZONE-ASTP-HQ',
    name: 'Arfa Software Technology Park Main Campus',
    description: 'Primary corporate IT campus polygon.',
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

  final sampleAgent = const FieldAgent(
    id: 'AGT-01',
    name: 'Zeeshan Ali',
    department: 'Logistics',
    role: 'Fleet Lead',
    currentLat: 31.4754,
    currentLng: 74.3436,
    speedKmh: 42.0,
    batteryLevelPercent: 92,
    isOnline: true,
    currentEtaMins: 10,
    destinationName: 'Main Campus',
  );

  Widget createSubject({required bool isDark, required DispatchBloc bloc}) {
    final fakeVoip = FakeVoipRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider<DispatchBloc>.value(value: bloc),
        BlocProvider<VoipBloc>(create: (_) => VoipBloc(fakeVoip)),
      ],
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const Scaffold(body: FieldTrackerView()),
      ),
    );
  }

  testWidgets(
    'FieldTrackerView displays active geofence zone and Draw Zone button',
    (WidgetTester tester) async {
      final dispatchRepo = FakeDispatchRepository();
      final geofenceRepo = FakeGeofenceRepository();
      geofenceRepo.zones = [sampleZone];
      dispatchRepo.agents = [sampleAgent];

      final bloc = DispatchBloc(dispatchRepo, geofenceRepo);

      await tester.pumpWidget(createSubject(isDark: true, bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.byType(FieldTrackerView), findsOneWidget);
      expect(find.text('Draw Zone'), findsOneWidget);
      expect(find.byIcon(Icons.layers), findsOneWidget);
      expect(find.byIcon(Icons.edit_location_alt), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FieldTrackerView activates Polygon Boundary Editor HUD on tapping Draw Zone',
    (WidgetTester tester) async {
      final dispatchRepo = FakeDispatchRepository();
      final geofenceRepo = FakeGeofenceRepository();
      geofenceRepo.zones = [sampleZone];
      dispatchRepo.agents = [sampleAgent];

      final bloc = DispatchBloc(dispatchRepo, geofenceRepo);

      await tester.pumpWidget(createSubject(isDark: false, bloc: bloc));
      await tester.pumpAndSettle();

      // Tap Draw Zone button
      await tester.tap(find.text('Draw Zone'));
      await tester.pumpAndSettle();

      expect(find.text('POLYGON BOUNDARY EDITOR'), findsOneWidget);
      expect(find.text('0 Vertices (Tap Map)'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FieldTrackerView renders cleanly on 800x360 landscape viewport with zero overflow',
    (WidgetTester tester) async {
      final dispatchRepo = FakeDispatchRepository();
      final geofenceRepo = FakeGeofenceRepository();
      geofenceRepo.zones = [sampleZone];
      dispatchRepo.agents = [sampleAgent];

      final bloc = DispatchBloc(dispatchRepo, geofenceRepo);

      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSubject(isDark: true, bloc: bloc));
      await tester.pumpAndSettle();

      expect(find.byType(FieldTrackerView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
