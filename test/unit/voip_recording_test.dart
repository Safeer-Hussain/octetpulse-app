import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/employee.dart';
import 'package:octet_pulse_app/domain/entities/voip_recording.dart';
import 'package:octet_pulse_app/domain/services/transcript_simulator.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_bloc.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_event.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('VoipRecording & TranscriptSimulator Unit Tests', () {
    test(
      'TranscriptSimulator generates complete encrypted recording manifest',
      () {
        final rec = TranscriptSimulator.simulateRecording(
          recordingId: 'REC-TEST-01',
          callId: 'CALL-102-ABC',
          calleeId: 'EMP-102',
          calleeName: 'Zainab Tariq',
          calleeRole: 'Lead Flutter Engineer',
          durationSeconds: 45,
          recordedAt: DateTime(2026, 11, 11, 10, 30),
        );

        expect(rec.id, 'REC-TEST-01');
        expect(rec.cipher, 'AES-256-GCM');
        expect(rec.checksumSha256.length, 64);
        expect(rec.durationSeconds, 45);
        expect(rec.formattedDuration, '00:45');
        expect(rec.fileSizeBytes, greaterThan(0));
        expect(rec.waveforms.length, 32);
        expect(rec.transcript.length, greaterThanOrEqualTo(4));
        expect(rec.checksumShort, contains('...'));
        expect(rec.transcript.first.formattedOffset, '00:01');
      },
    );

    test(
      'VoipRecording serialization toMap and fromMap roundtrip preserves data',
      () {
        final rec = TranscriptSimulator.simulateRecording(
          recordingId: 'REC-TEST-02',
          callId: 'CALL-105-DEF',
          calleeId: 'EMP-105',
          calleeName: 'Tariq Mahmood',
          calleeRole: 'Field Operations Specialist',
          durationSeconds: 30,
          recordedAt: DateTime(2026, 11, 11, 14, 0),
        );

        final map = rec.toMap();
        final reconstituted = VoipRecording.fromMap(map);

        expect(reconstituted.id, rec.id);
        expect(reconstituted.callId, rec.callId);
        expect(reconstituted.calleeId, rec.calleeId);
        expect(reconstituted.calleeName, rec.calleeName);
        expect(reconstituted.cipher, 'AES-256-GCM');
        expect(reconstituted.checksumSha256, rec.checksumSha256);
        expect(reconstituted.transcript.length, rec.transcript.length);
        expect(reconstituted.waveforms.length, rec.waveforms.length);
      },
    );

    test('TranscriptToken formatting and serialization', () {
      const token = TranscriptToken(
        offsetMs: 75000,
        speaker: 'Coordinator',
        text: 'Testing audio scrub buffer',
        confidence: 0.99,
      );

      expect(token.formattedOffset, '01:15');
      final map = token.toMap();
      final roundtrip = TranscriptToken.fromMap(map);
      expect(roundtrip, token);
    });
  });

  group('VoipBloc Recording & Playback State Machine Tests', () {
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

    blocTest<VoipBloc, VoipState>(
      'start recording fails if no active call session',
      build: () => VoipBloc(repository),
      act: (bloc) => bloc.add(const StartVoipRecordingEvent()),
      verify: (bloc) {
        expect(bloc.state.isRecording, false);
        expect(bloc.state.errorMessage, contains('Cannot record audio'));
      },
    );

    blocTest<VoipBloc, VoipState>(
      'starts recording during active call session',
      build: () => VoipBloc(repository),
      seed: () => const VoipState(
        isCallActive: true,
        callStatus: VoipCallStatus.active,
        activeCalleeId: 'EMP-102',
        activeCalleeName: 'Zainab Tariq',
      ),
      act: (bloc) => bloc.add(const StartVoipRecordingEvent()),
      verify: (bloc) {
        expect(bloc.state.isRecording, true);
        expect(
          bloc.state.feedbackMessage,
          contains('Call recording activated'),
        );
      },
    );

    blocTest<VoipBloc, VoipState>(
      'stops recording during active call and saves manifest',
      build: () => VoipBloc(repository),
      seed: () => const VoipState(
        isCallActive: true,
        isRecording: true,
        callStatus: VoipCallStatus.active,
        activeCalleeId: 'EMP-102',
        activeCalleeName: 'Zainab Tariq',
        activeCalleeRole: 'Lead Flutter Engineer',
      ),
      act: (bloc) => bloc.add(const StopVoipRecordingEvent()),
      verify: (bloc) {
        expect(bloc.state.isRecording, false);
        expect(bloc.state.recordings.length, 1);
        expect(bloc.state.recordings.first.calleeName, 'Zainab Tariq');
        expect(bloc.state.recordings.first.cipher, 'AES-256-GCM');
      },
    );

    blocTest<VoipBloc, VoipState>(
      'ending an active call auto-finalizes and persists active recording',
      build: () => VoipBloc(repository),
      seed: () => const VoipState(
        isCallActive: true,
        isRecording: true,
        callStatus: VoipCallStatus.active,
        activeCalleeId: 'EMP-102',
        activeCalleeName: 'Zainab Tariq',
        activeCalleeRole: 'Lead Flutter Engineer',
      ),
      act: (bloc) => bloc.add(const EndVoipCallEvent()),
      verify: (bloc) {
        expect(bloc.state.isCallActive, false);
        expect(bloc.state.isRecording, false);
        expect(bloc.state.callLogs.length, 1);
        expect(bloc.state.recordings.length, 1);
        expect(bloc.state.recordings.first.calleeName, 'Zainab Tariq');
      },
    );

    blocTest<VoipBloc, VoipState>(
      'selects recording for playback and seeks progress',
      build: () => VoipBloc(repository),
      act: (bloc) {
        final rec = TranscriptSimulator.simulateRecording(
          recordingId: 'REC-PLAY-1',
          callId: 'CALL-1',
          calleeId: 'EMP-102',
          calleeName: 'Zainab Tariq',
          calleeRole: 'Lead Flutter Engineer',
          durationSeconds: 60,
        );
        bloc.add(SelectRecordingForPlaybackEvent(rec));
        bloc.add(const SeekRecordingPlaybackEvent(0.45));
      },
      verify: (bloc) {
        expect(bloc.state.selectedRecording?.id, 'REC-PLAY-1');
        expect(bloc.state.playbackProgress, 0.45);
      },
    );

    blocTest<VoipBloc, VoipState>(
      'deletes recording and updates state list',
      build: () => VoipBloc(repository),
      seed: () {
        final rec = TranscriptSimulator.simulateRecording(
          recordingId: 'REC-DEL-1',
          callId: 'CALL-1',
          calleeId: 'EMP-102',
          calleeName: 'Zainab Tariq',
          calleeRole: 'Lead Flutter Engineer',
          durationSeconds: 30,
        );
        return VoipState(recordings: [rec], selectedRecording: rec);
      },
      act: (bloc) => bloc.add(const DeleteVoipRecordingEvent('REC-DEL-1')),
      verify: (bloc) {
        expect(bloc.state.recordings.isEmpty, true);
        expect(bloc.state.selectedRecording, null);
      },
    );
  });
}
