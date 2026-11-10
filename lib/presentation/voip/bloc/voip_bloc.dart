import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/voip_call_log.dart';
import '../../../domain/repositories/voip_repository.dart';
import 'voip_event.dart';
import 'voip_state.dart';

class VoipBloc extends Bloc<VoipEvent, VoipState> {
  final VoipRepository _repository;
  final Uuid _uuid = const Uuid();
  StreamSubscription? _telemetrySubscription;

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

    _telemetrySubscription = _repository.getTelemetryStream().listen((telemetry) {
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

      emit(state.copyWith(
        directory: directory,
        filteredDirectory: directory,
        callLogs: logs,
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to load VoIP data: $e'));
    }
  }

  Future<void> _onInitiateCall(
    InitiateVoipCallEvent event,
    Emitter<VoipState> emit,
  ) async {
    emit(state.copyWith(
      callStatus: VoipCallStatus.calling,
      activeCalleeId: event.calleeId,
      activeCalleeName: event.calleeName,
      activeCalleeRole: event.calleeRole,
      isCallActive: true,
      activeTab: 1, // Auto-switch to Call Cockpit
      feedbackMessage: 'Establishing encrypted SRTP-AES256 session with ${event.calleeName}...',
    ));

    try {
      final res = await _repository.initiateCall(
        calleeId: event.calleeId,
        calleeName: event.calleeName,
      );

      final callId = res['callId'] as String? ?? 'call_active';

      emit(state.copyWith(
        callStatus: VoipCallStatus.active,
        activeCallId: callId,
        feedbackMessage: 'Connected securely. Cipher: SRTP-AES256.',
      ));
    } catch (e) {
      emit(state.copyWith(
        callStatus: VoipCallStatus.error,
        errorMessage: 'VoIP connection failed: $e',
      ));
    }
  }

  Future<void> _onEndCall(
    EndVoipCallEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final res = await _repository.endCall();
      final duration = res['durationSeconds'] as int? ?? state.telemetry.callDurationSec;

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

        emit(state.copyWith(
          callStatus: VoipCallStatus.idle,
          clearActiveCall: true,
          isCallActive: false,
          callLogs: updatedLogs,
          dtmfBuffer: '',
          feedbackMessage: 'Call terminated. Duration: ${duration}s.',
        ));
      } else {
        emit(state.copyWith(
          callStatus: VoipCallStatus.idle,
          clearActiveCall: true,
          isCallActive: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        callStatus: VoipCallStatus.idle,
        clearActiveCall: true,
        isCallActive: false,
        errorMessage: 'Error terminating call: $e',
      ));
    }
  }

  Future<void> _onToggleMute(
    ToggleVoipMuteEvent event,
    Emitter<VoipState> emit,
  ) async {
    try {
      final isMuted = await _repository.toggleMute();
      emit(state.copyWith(
        isMuted: isMuted,
        feedbackMessage: isMuted ? 'Microphone muted.' : 'Microphone unmuted.',
      ));
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
      emit(state.copyWith(
        isSpeakerOn: isSpeaker,
        feedbackMessage: isSpeaker ? 'Speakerphone active.' : 'Handset earpiece active.',
      ));
    } catch (_) {
      emit(state.copyWith(isSpeakerOn: !state.isSpeakerOn));
    }
  }

  void _onToggleHold(
    ToggleVoipHoldEvent event,
    Emitter<VoipState> emit,
  ) {
    final nextHold = !state.isOnHold;
    emit(state.copyWith(
      isOnHold: nextHold,
      feedbackMessage: nextHold ? 'Call placed on hold.' : 'Call resumed.',
    ));
  }

  void _onSendDtmfTone(
    SendDtmfToneEvent event,
    Emitter<VoipState> emit,
  ) {
    final updated = state.dtmfBuffer + event.digit;
    emit(state.copyWith(dtmfBuffer: updated));
  }

  void _onTelemetryReceived(
    TelemetryReceivedEvent event,
    Emitter<VoipState> emit,
  ) {
    emit(state.copyWith(
      telemetry: event.telemetry,
      isMuted: event.telemetry.isMuted,
      isSpeakerOn: event.telemetry.isSpeakerOn,
    ));
  }

  void _onSearchDirectory(
    SearchDirectoryEvent event,
    Emitter<VoipState> emit,
  ) {
    final query = event.query.toLowerCase().trim();
    if (query.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredDirectory: state.directory,
      ));
      return;
    }

    final filtered = state.directory.where((emp) {
      return emp.name.toLowerCase().contains(query) ||
          emp.department.toLowerCase().contains(query) ||
          emp.role.toLowerCase().contains(query) ||
          emp.email.toLowerCase().contains(query);
    }).toList();

    emit(state.copyWith(
      searchQuery: event.query,
      filteredDirectory: filtered,
    ));
  }

  void _onSwitchVoipTab(
    SwitchVoipTabEvent event,
    Emitter<VoipState> emit,
  ) {
    emit(state.copyWith(activeTab: event.tabIndex));
  }

  @override
  Future<void> close() {
    _telemetrySubscription?.cancel();
    return super.close();
  }
}
