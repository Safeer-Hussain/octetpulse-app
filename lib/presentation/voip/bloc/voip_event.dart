import 'package:equatable/equatable.dart';
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
