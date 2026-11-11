import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/voip_call_log.dart';
import '../../../domain/entities/voip_recording.dart';
import '../../../domain/repositories/voip_repository.dart';
import '../../../domain/services/transcript_simulator.dart';
import 'voip_event.dart';
import 'voip_state.dart';

class VoipBloc extends Bloc<VoipEvent, VoipState> {
  final VoipRepository _repository;
  final Uuid _uuid = const Uuid();
  StreamSubscription? _telemetrySubscription;
  Timer? _playbackTimer;

  VoipBloc(this._repository) : super(const VoipState()) {
    on<LoadVoipDirectoryAndLogs>(_onLoadDirectoryAndLogs);
    on<InitiateVoipCallEvent>(_onInitiateCall);
    on<EndVoipCallEvent>(_onEndCall);
    on<ToggleVoipMuteEvent>(_onToggleMute);
    on<ToggleVoipSpeakerEvent>(_onToggleSpeaker);
    on<ToggleVoipHoldEvent>(_onToggleHold);
    on<SendDtmfToneEvent>(_onSendDtmfTone);
    on<TelemetryReceivedEvent>(_onTelemetryReceived);
    on<SearchDirectoryEvent>(_onSearchDirectory);
    on<SwitchVoipTabEvent>(_onSwitchVoipTab);
    on<LoadVoipRecordingsEvent>(_onLoadRecordings);
    on<StartVoipRecordingEvent>(_onStartRecording);
    on<StopVoipRecordingEvent>(_onStopRecording);
    on<ToggleVoipRecordingEvent>(_onToggleRecording);
    on<DeleteVoipRecordingEvent>(_onDeleteRecording);
    on<SelectRecordingForPlaybackEvent>(_onSelectRecordingForPlayback);
    on<SeekRecordingPlaybackEvent>(_onSeekPlayback);
    on<ToggleRecordingPlaybackPlayPauseEvent>(_onTogglePlaybackPlayPause);
    on<RecordingPlaybackTickEvent>(_onPlaybackTick);

    _telemetrySubscription = _repository.getTelemetryStream().listen((
      telemetry,
    ) {
      add(TelemetryReceivedEvent(telemetry));
    });
  }

  Future<void> _onLoadDirectoryAndLogs(
    LoadVoipDirectoryAndLogs event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final directory = await _repository.getDirectory();
      final logs = await _repository.getCallLogs();
      final recordings = await _repository.getRecordings();

      emit(
        state.copyWith(
          directory: directory,
          filteredDirectory: directory,
          callLogs: logs,
          recordings: recordings,
          selectedRecording: recordings.isNotEmpty ? recordings.first : null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to load VoIP data: $e'));
    }
  }

  Future<void> _onInitiateCall(
    InitiateVoipCallEvent event,
    Emitter<VoipState> emit,
  ) async {
    emit(
      state.copyWith(
        callStatus: VoipCallStatus.calling,
        activeCalleeId: event.calleeId,
        activeCalleeName: event.calleeName,
        activeCalleeRole: event.calleeRole,
        isCallActive: true,
        activeTab: 1, // Auto-switch to Call Cockpit
        feedbackMessage:
            'Establishing encrypted SRTP-AES256 session with ${event.calleeName}...',
      ),
    );

    try {
      final res = await _repository.initiateCall(
        calleeId: event.calleeId,
        calleeName: event.calleeName,
      );

      final callId = res['callId'] as String? ?? 'call_active';

      emit(
        state.copyWith(
          callStatus: VoipCallStatus.active,
          activeCallId: callId,
          feedbackMessage: 'Connected securely. Cipher: SRTP-AES256.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          callStatus: VoipCallStatus.error,
          errorMessage: 'VoIP connection failed: $e',
        ),
      );
    }
  }

  Future<void> _onEndCall(
    EndVoipCallEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final res = await _repository.endCall();
      final duration =
          res['durationSeconds'] as int? ?? state.telemetry.callDurationSec;

      List<VoipRecording> updatedRecordings = state.recordings;
      if (state.isRecording && state.activeCalleeId != null) {
        try {
          await _repository.stopRecording();
          final recId = 'REC-${_uuid.v4().substring(0, 6).toUpperCase()}';
          final recording = TranscriptSimulator.simulateRecording(
            recordingId: recId,
            callId:
                state.activeCallId ??
                'CALL-${DateTime.now().millisecondsSinceEpoch}',
            calleeId: state.activeCalleeId!,
            calleeName: state.activeCalleeName ?? 'Colleague',
            calleeRole: state.activeCalleeRole ?? 'Enterprise Member',
            durationSeconds: duration > 0 ? duration : 1,
            recordedAt: DateTime.now(),
          );
          await _repository.saveRecording(recording);
          updatedRecordings = [recording, ...state.recordings];
        } catch (_) {}
      }

      if (state.activeCalleeId != null) {
        final log = VoipCallLog(
          id: 'CALL-${_uuid.v4().substring(0, 6).toUpperCase()}',
          calleeId: state.activeCalleeId!,
          calleeName: state.activeCalleeName ?? 'Colleague',
          calleeRole: state.activeCalleeRole ?? 'Enterprise Member',
          callType: 'Outbound',
          durationSeconds: duration,
          timestamp: DateTime.now(),
          cipher: 'SRTP-AES256',
          audioCodec: state.telemetry.audioCodec,
          mosScore: state.telemetry.mosScore,
        );

        await _repository.logCompletedCall(log);
        final updatedLogs = [log, ...state.callLogs];

        emit(
          state.copyWith(
            callStatus: VoipCallStatus.idle,
            clearActiveCall: true,
            isCallActive: false,
            isRecording: false,
            callLogs: updatedLogs,
            recordings: updatedRecordings,
            dtmfBuffer: '',
            feedbackMessage: state.isRecording
                ? 'Call ended. Recording encrypted & sealed in vault.'
                : 'Call terminated. Duration: ${duration}s.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            callStatus: VoipCallStatus.idle,
            clearActiveCall: true,
            isCallActive: false,
            isRecording: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          callStatus: VoipCallStatus.idle,
          clearActiveCall: true,
          isCallActive: false,
          isRecording: false,
          errorMessage: 'Error terminating call: $e',
        ),
      );
    }
  }

  Future<void> _onToggleMute(
    ToggleVoipMuteEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final isMuted = await _repository.toggleMute();
      emit(
        state.copyWith(
          isMuted: isMuted,
          feedbackMessage: isMuted
              ? 'Microphone muted.'
              : 'Microphone unmuted.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isMuted: !state.isMuted));
    }
  }

  Future<void> _onToggleSpeaker(
    ToggleVoipSpeakerEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final isSpeaker = await _repository.toggleSpeaker();
      emit(
        state.copyWith(
          isSpeakerOn: isSpeaker,
          feedbackMessage: isSpeaker
              ? 'Speakerphone active.'
              : 'Handset earpiece active.',
        ),
      );
    } catch (_) {
      emit(state.copyWith(isSpeakerOn: !state.isSpeakerOn));
    }
  }

  void _onToggleHold(ToggleVoipHoldEvent event, Emitter<VoipState> emit) {
    final nextHold = !state.isOnHold;
    emit(
      state.copyWith(
        isOnHold: nextHold,
        feedbackMessage: nextHold ? 'Call placed on hold.' : 'Call resumed.',
      ),
    );
  }

  void _onSendDtmfTone(SendDtmfToneEvent event, Emitter<VoipState> emit) {
    final updated = state.dtmfBuffer + event.digit;
    emit(state.copyWith(dtmfBuffer: updated));
  }

  void _onTelemetryReceived(
    TelemetryReceivedEvent event,
    Emitter<VoipState> emit,
  ) {
    emit(
      state.copyWith(
        telemetry: event.telemetry,
        isMuted: event.telemetry.isMuted,
        isSpeakerOn: event.telemetry.isSpeakerOn,
        isRecording: event.telemetry.isRecording || state.isRecording,
      ),
    );
  }

  void _onSearchDirectory(SearchDirectoryEvent event, Emitter<VoipState> emit) {
    final query = event.query.toLowerCase().trim();
    if (query.isEmpty) {
      emit(state.copyWith(searchQuery: '', filteredDirectory: state.directory));
      return;
    }

    final filtered = state.directory.where((emp) {
      return emp.name.toLowerCase().contains(query) ||
          emp.department.toLowerCase().contains(query) ||
          emp.role.toLowerCase().contains(query) ||
          emp.email.toLowerCase().contains(query);
    }).toList();

    emit(state.copyWith(searchQuery: event.query, filteredDirectory: filtered));
  }

  void _onSwitchVoipTab(SwitchVoipTabEvent event, Emitter<VoipState> emit) {
    emit(state.copyWith(activeTab: event.tabIndex));
  }

  Future<void> _onLoadRecordings(
    LoadVoipRecordingsEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final recordings = await _repository.getRecordings();
      emit(
        state.copyWith(
          recordings: recordings,
          selectedRecording: recordings.isNotEmpty ? recordings.first : null,
        ),
      );
    } catch (_) {}
  }

  Future<void> _onStartRecording(
    StartVoipRecordingEvent event,
    Emitter<VoipState> emit,
  ) async {
    if (!state.isCallActive) {
      emit(
        state.copyWith(
          errorMessage: 'Cannot record audio without an active call session.',
        ),
      );
      return;
    }
    try {
      await _repository.startRecording(
        callId: state.activeCallId ?? 'call_active',
      );
      emit(
        state.copyWith(
          isRecording: true,
          feedbackMessage: 'Call recording activated [AES-256-GCM buffer].',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to start recording: $e'));
    }
  }

  Future<void> _onStopRecording(
    StopVoipRecordingEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      await _repository.stopRecording();
      if (state.isCallActive && state.activeCalleeId != null) {
        final duration = state.telemetry.callDurationSec;
        final recId = 'REC-${_uuid.v4().substring(0, 6).toUpperCase()}';
        final recording = TranscriptSimulator.simulateRecording(
          recordingId: recId,
          callId: state.activeCallId ?? 'call_active',
          calleeId: state.activeCalleeId!,
          calleeName: state.activeCalleeName ?? 'Colleague',
          calleeRole: state.activeCalleeRole ?? 'Enterprise Member',
          durationSeconds: duration > 0 ? duration : 5,
        );
        await _repository.saveRecording(recording);
        emit(
          state.copyWith(
            isRecording: false,
            recordings: [recording, ...state.recordings],
            feedbackMessage:
                'Call recording stopped & encrypted with AES-256-GCM.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            isRecording: false,
            feedbackMessage: 'Call recording stopped.',
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to stop recording: $e'));
    }
  }

  Future<void> _onToggleRecording(
    ToggleVoipRecordingEvent event,
    Emitter<VoipState> emit,
  ) async {
    if (state.isRecording) {
      await _onStopRecording(const StopVoipRecordingEvent(), emit);
    } else {
      await _onStartRecording(const StartVoipRecordingEvent(), emit);
    }
  }

  Future<void> _onDeleteRecording(
    DeleteVoipRecordingEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      await _repository.deleteRecording(event.recordingId);
      final updated = state.recordings
          .where((r) => r.id != event.recordingId)
          .toList();
      final wasSelected = state.selectedRecording?.id == event.recordingId;
      emit(
        state.copyWith(
          recordings: updated,
          clearSelectedRecording: wasSelected,
          isPlayingRecording: wasSelected ? false : state.isPlayingRecording,
          playbackProgress: wasSelected ? 0.0 : state.playbackProgress,
          feedbackMessage: 'Encrypted call recording deleted.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete recording: $e'));
    }
  }

  void _onSelectRecordingForPlayback(
    SelectRecordingForPlaybackEvent event,
    Emitter<VoipState> emit,
  ) {
    _playbackTimer?.cancel();
    emit(
      state.copyWith(
        selectedRecording: event.recording,
        clearSelectedRecording: event.recording == null,
        playbackProgress: 0.0,
        isPlayingRecording: false,
      ),
    );
  }

  void _onSeekPlayback(
    SeekRecordingPlaybackEvent event,
    Emitter<VoipState> emit,
  ) {
    emit(state.copyWith(playbackProgress: event.progress.clamp(0.0, 1.0)));
  }

  void _onTogglePlaybackPlayPause(
    ToggleRecordingPlaybackPlayPauseEvent event,
    Emitter<VoipState> emit,
  ) {
    VoipRecording? currentRec = state.selectedRecording;
    if (currentRec == null && state.recordings.isNotEmpty) {
      currentRec = state.recordings.first;
      emit(state.copyWith(selectedRecording: currentRec));
    }

    if (currentRec == null) return;

    if (state.isPlayingRecording) {
      _playbackTimer?.cancel();
      emit(state.copyWith(isPlayingRecording: false));
    } else {
      _playbackTimer?.cancel();
      var currentProgress = state.playbackProgress >= 1.0
          ? 0.0
          : state.playbackProgress;
      emit(
        state.copyWith(
          isPlayingRecording: true,
          playbackProgress: currentProgress,
        ),
      );

      _playbackTimer = Timer.periodic(const Duration(milliseconds: 300), (
        timer,
      ) {
        final next = currentProgress + 0.04;
        if (next >= 1.0) {
          timer.cancel();
          add(const RecordingPlaybackTickEvent(1.0));
        } else {
          currentProgress = next;
          add(RecordingPlaybackTickEvent(next));
        }
      });
    }
  }

  void _onPlaybackTick(
    RecordingPlaybackTickEvent event,
    Emitter<VoipState> emit,
  ) {
    final isDone = event.progress >= 1.0;
    emit(
      state.copyWith(
        playbackProgress: isDone ? 1.0 : event.progress,
        isPlayingRecording: !isDone && state.isPlayingRecording,
      ),
    );
  }

  @override
  Future<void> close() {
    _telemetrySubscription?.cancel();
    _playbackTimer?.cancel();
    return super.close();
  }
}
