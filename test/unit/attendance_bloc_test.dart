import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/presentation/attendance/bloc/attendance_bloc.dart';
import 'package:octet_pulse_app/presentation/attendance/bloc/attendance_event.dart';
import 'package:octet_pulse_app/presentation/attendance/bloc/attendance_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('AttendanceBloc Unit Tests', () {
    late FakeAttendanceRepository repository;

    setUp(() {
      repository = FakeAttendanceRepository();
    });

    test('initial state is AttendanceStatusState.initial', () {
      final bloc = AttendanceBloc(repository);
      expect(bloc.state.status, AttendanceStatusState.initial);
      expect(bloc.state.isClockedIn, false);
      bloc.close();
    });

    blocTest<AttendanceBloc, AttendanceState>(
      'emits updated history and active record on ClockInEvent',
      build: () => AttendanceBloc(repository),
      act: (bloc) => bloc.add(
        const ClockInEvent(
          employeeId: 'EMP-101',
          employeeName: 'Safeer Hussain',
          latitude: 31.4754,
          longitude: 74.3436,
          isWithinGeofence: true,
          geofenceDistanceMeters: 20.0,
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.isClockedIn, true);
        expect(bloc.state.history.length, 1);
        expect(bloc.state.history.first.employeeName, 'Safeer Hussain');
      },
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'toggles break from Clocked In to On Break and back',
      build: () => AttendanceBloc(repository),
      seed: () {
        return const AttendanceState();
      },
      act: (bloc) async {
        bloc.add(
          const ClockInEvent(
            employeeId: 'EMP-101',
            employeeName: 'Safeer Hussain',
            latitude: 31.4754,
            longitude: 74.3436,
            isWithinGeofence: true,
            geofenceDistanceMeters: 20.0,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ToggleBreakEvent());
      },
      verify: (bloc) {
        expect(bloc.state.isOnBreak, true);
        expect(bloc.state.currentRecord?.status, 'On Break');
      },
    );

    blocTest<AttendanceBloc, AttendanceState>(
      'clears current record on ClockOutEvent',
      build: () => AttendanceBloc(repository),
      act: (bloc) async {
        bloc.add(
          const ClockInEvent(
            employeeId: 'EMP-101',
            employeeName: 'Safeer Hussain',
            latitude: 31.4754,
            longitude: 74.3436,
            isWithinGeofence: true,
            geofenceDistanceMeters: 20.0,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        bloc.add(const ClockOutEvent());
      },
      verify: (bloc) {
        expect(bloc.state.isClockedIn, false);
        expect(bloc.state.currentRecord, isNull);
        expect(bloc.state.history.first.status, 'Clocked Out');
      },
    );
  });
}
