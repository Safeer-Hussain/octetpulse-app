import 'package:equatable/equatable.dart';

import '../../../domain/entities/employee.dart';
import '../../../domain/entities/voip_call_log.dart';
import '../../../domain/entities/voip_telemetry.dart';

enum VoipCallStatus { idle, calling, active, ended, error }

class VoipState extends Equatable {
  final VoipCallStatus callStatus;
  final List<Employee> directory;
  final List<Employee> filteredDirectory;
  final List<VoipCallLog> callLogs;
  final String? activeCalleeId;
  final String? activeCalleeName;
  final String? activeCalleeRole;
  final String? activeCallId;
  final VoipTelemetry telemetry;
  final bool isCallActive;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isOnHold;
  final String dtmfBuffer;
  final int activeTab; // 0 = Directory & Channels, 1 = Call Cockpit & Keypad
  final String searchQuery;
  final String? feedbackMessage;
  final String? errorMessage;

  const VoipState({
    this.callStatus = VoipCallStatus.idle,
    this.directory = const [],
    this.filteredDirectory = const [],
    this.callLogs = const [],
    this.activeCalleeId,
    this.activeCalleeName,
    this.activeCalleeRole,
    this.activeCallId,
    this.telemetry = const VoipTelemetry(),
    this.isCallActive = false,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isOnHold = false,
    this.dtmfBuffer = '',
    this.activeTab = 0,
    this.searchQuery = '',
    this.feedbackMessage,
    this.errorMessage,
  });

  VoipState copyWith({
    VoipCallStatus? callStatus,
    List<Employee>? directory,
    List<Employee>? filteredDirectory,
    List<VoipCallLog>? callLogs,
    String? activeCalleeId,
    String? activeCalleeName,
    String? activeCalleeRole,
    String? activeCallId,
    bool clearActiveCall = false,
    VoipTelemetry? telemetry,
    bool? isCallActive,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isOnHold,
    String? dtmfBuffer,
    int? activeTab,
    String? searchQuery,
    String? feedbackMessage,
    String? errorMessage,
  }) {
    return VoipState(
      callStatus: callStatus ?? this.callStatus,
      directory: directory ?? this.directory,
      filteredDirectory: filteredDirectory ?? this.filteredDirectory,
      callLogs: callLogs ?? this.callLogs,
      activeCalleeId: clearActiveCall
          ? null
          : (activeCalleeId ?? this.activeCalleeId),
      activeCalleeName: clearActiveCall
          ? null
          : (activeCalleeName ?? this.activeCalleeName),
      activeCalleeRole: clearActiveCall
          ? null
          : (activeCalleeRole ?? this.activeCalleeRole),
      activeCallId: clearActiveCall
          ? null
          : (activeCallId ?? this.activeCallId),
      telemetry: telemetry ?? this.telemetry,
      isCallActive: isCallActive ?? this.isCallActive,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isOnHold: isOnHold ?? this.isOnHold,
      dtmfBuffer: dtmfBuffer ?? this.dtmfBuffer,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      feedbackMessage: feedbackMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    callStatus,
    directory,
    filteredDirectory,
    callLogs,
    activeCalleeId,
    activeCalleeName,
    activeCalleeRole,
    activeCallId,
    telemetry,
    isCallActive,
    isMuted,
    isSpeakerOn,
    isOnHold,
    dtmfBuffer,
    activeTab,
    searchQuery,
    feedbackMessage,
    errorMessage,
  ];
}
