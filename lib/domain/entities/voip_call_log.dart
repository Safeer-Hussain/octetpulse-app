import 'package:equatable/equatable.dart';

class VoipCallLog extends Equatable {
  final String id;
  final String calleeId;
  final String calleeName;
  final String calleeRole;
  final String callType; // 'Outbound', 'Inbound', 'Missed'
  final int durationSeconds;
  final DateTime timestamp;
  final String cipher; // 'SRTP-AES256'
  final String audioCodec; // 'OPUS-HD', 'G722'
  final double mosScore;

  const VoipCallLog({
    required this.id,
    required this.calleeId,
    required this.calleeName,
    required this.calleeRole,
    required this.callType,
    required this.durationSeconds,
    required this.timestamp,
    required this.cipher,
    required this.audioCodec,
    required this.mosScore,
  });

  @override
  List<Object?> get props => [
    id,
    calleeId,
    calleeName,
    calleeRole,
    callType,
    durationSeconds,
    timestamp,
    cipher,
    audioCodec,
    mosScore,
  ];
}
