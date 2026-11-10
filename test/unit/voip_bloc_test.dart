import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/employee.dart';
import 'package:octet_pulse_app/domain/entities/voip_telemetry.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_bloc.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_event.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('VoipBloc Unit Tests', () {
    late FakeVoipRepository repository;

    final sampleEmployee = const Employee(
      id: 'EMP-102',
      name: 'Zainab Tariq',
      email: 'zainab.t@octetpulse.io',
      department: 'Mobile Engineering',
      role: 'Lead Flutter Engineer',
      avatarAsset: 'assets/images/avatar_mobile.png',
      baseSalaryUsd: 7500.0,
      hourlyRateUsd: 46.88,
      presenceStatus: 'Available',
    );

    setUp(() {
      repository = FakeVoipRepository();
      repository.directory = [sampleEmployee];
    });

    test('initial callStatus is VoipCallStatus.idle', () {
      final bloc = VoipBloc(repository);
      expect(bloc.state.callStatus, VoipCallStatus.idle);
      expect(bloc.state.isCallActive, false);
      bloc.close();
    });

    blocTest<VoipBloc, VoipState>(
      'initiates call, transitions callStatus to active and switches to tab 1',
      build: () => VoipBloc(repository),
      act: (bloc) => bloc.add(
        const InitiateVoipCallEvent(
          calleeId: 'EMP-102',
          calleeName: 'Zainab Tariq',
          calleeRole: 'Lead Flutter Engineer',
        ),
      ),
      verify: (bloc) {
        expect(bloc.state.callStatus, VoipCallStatus.active);
        expect(bloc.state.isCallActive, true);
        expect(bloc.state.activeTab, 1);
        expect(bloc.state.activeCalleeName, 'Zainab Tariq');
      },
    );

    blocTest<VoipBloc, VoipState>(
      'receives telemetry stream and updates waveforms and mos score',
      build: () => VoipBloc(repository),
      act: (bloc) {
        repository.emitTelemetry(
          const VoipTelemetry(
            isActive: true,
            callDurationSec: 42,
            bitrateKbps: 64.0,
            mosScore: 4.41,
            cipher: 'SRTP-AES256',
            audioCodec: 'OPUS-HD',
            waveforms: [0.2, 0.5, 0.8, 0.4],
          ),
        );
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.telemetry.mosScore, 4.41);
        expect(bloc.state.telemetry.callDurationSec, 42);
        expect(bloc.state.telemetry.waveforms.length, 4);
      },
    );

    blocTest<VoipBloc, VoipState>(
      'ends call and logs call to callLogs',
      build: () => VoipBloc(repository),
      seed: () => const VoipState(
        isCallActive: true,
        callStatus: VoipCallStatus.active,
        activeCalleeId: 'EMP-102',
        activeCalleeName: 'Zainab Tariq',
        activeCalleeRole: 'Lead Flutter Engineer',
      ),
      act: (bloc) => bloc.add(const EndVoipCallEvent()),
      verify: (bloc) {
        expect(bloc.state.isCallActive, false);
        expect(bloc.state.callStatus, VoipCallStatus.idle);
        expect(bloc.state.callLogs.length, 1);
        expect(bloc.state.callLogs.first.calleeName, 'Zainab Tariq');
      },
    );
  });
}
