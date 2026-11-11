import 'package:equatable/equatable.dart';

import '../../../domain/entities/voip_recording.dart';
import '../../../domain/entities/voip_telemetry.dart';

abstract class VoipEvent extends Equatable {
  const VoipEvent();

  @override
  List<Object?> get props => [];
}

class LoadVoipDirectoryAndLogs extends VoipEvent {
  const LoadVoipDirectoryAndLogs();
}

class InitiateVoipCallEvent extends VoipEvent {
  final String calleeId;
  final String calleeName;
  final String calleeRole;

  const InitiateVoipCallEvent({
    required this.calleeId,
    required this.calleeName,
    required this.calleeRole,
  });

  @override
  List<Object?> get props => [calleeId, calleeName, calleeRole];
}

class EndVoipCallEvent extends VoipEvent {
  const EndVoipCallEvent();
}

class ToggleVoipMuteEvent extends VoipEvent {
  const ToggleVoipMuteEvent();
}

class ToggleVoipSpeakerEvent extends VoipEvent {
  const ToggleVoipSpeakerEvent();
}

class ToggleVoipHoldEvent extends VoipEvent {
  const ToggleVoipHoldEvent();
}

class SendDtmfToneEvent extends VoipEvent {
  final String digit;

  const SendDtmfToneEvent(this.digit);

  @override
  List<Object?> get props => [digit];
}

class TelemetryReceivedEvent extends VoipEvent {
  final VoipTelemetry telemetry;

  const TelemetryReceivedEvent(this.telemetry);

  @override
  List<Object?> get props => [telemetry];
}

class SearchDirectoryEvent extends VoipEvent {
  final String query;

  const SearchDirectoryEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SwitchVoipTabEvent extends VoipEvent {
  final int tabIndex;

  const SwitchVoipTabEvent(this.tabIndex);

  @override
  List<Object?> get props => [tabIndex];
}

class LoadVoipRecordingsEvent extends VoipEvent {
  const LoadVoipRecordingsEvent();
}

class StartVoipRecordingEvent extends VoipEvent {
  const StartVoipRecordingEvent();
}

class StopVoipRecordingEvent extends VoipEvent {
  const StopVoipRecordingEvent();
}

class ToggleVoipRecordingEvent extends VoipEvent {
  const ToggleVoipRecordingEvent();
}

class DeleteVoipRecordingEvent extends VoipEvent {
  final String recordingId;

  const DeleteVoipRecordingEvent(this.recordingId);

  @override
  List<Object?> get props => [recordingId];
}

class SelectRecordingForPlaybackEvent extends VoipEvent {
  final VoipRecording? recording;

  const SelectRecordingForPlaybackEvent(this.recording);

  @override
  List<Object?> get props => [recording];
}

class SeekRecordingPlaybackEvent extends VoipEvent {
  final double progress;

  const SeekRecordingPlaybackEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}

class ToggleRecordingPlaybackPlayPauseEvent extends VoipEvent {
  const ToggleRecordingPlaybackPlayPauseEvent();
}

class RecordingPlaybackTickEvent extends VoipEvent {
  final double progress;

  const RecordingPlaybackTickEvent(this.progress);

  @override
  List<Object?> get props => [progress];
}
