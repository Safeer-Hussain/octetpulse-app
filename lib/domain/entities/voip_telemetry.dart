import 'package:equatable/equatable.dart';

class VoipTelemetry extends Equatable {
  final bool isActive;
  final String callId;
  final int callDurationSec;
  final double bitrateKbps;
  final double packetLossPercent;
  final double jitterMs;
  final double mosScore;
  final String cipher;
  final String audioCodec;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isRecording;
  final List<double> waveforms;
  final int timestamp;

  const VoipTelemetry({
    this.isActive = false,
    this.callId = '',
    this.callDurationSec = 0,
    this.bitrateKbps = 0.0,
    this.packetLossPercent = 0.0,
    this.jitterMs = 0.0,
    this.mosScore = 4.40,
    this.cipher = 'SRTP-AES256',
    this.audioCodec = 'OPUS-HD',
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isRecording = false,
    this.waveforms = const [],
    this.timestamp = 0,
  });

  factory VoipTelemetry.fromMap(Map<dynamic, dynamic> map) {
    final rawWaveforms = map['waveforms'] as List<dynamic>? ?? [];
    final waveformsList = rawWaveforms
        .map((e) => (e as num).toDouble())
        .toList();

    return VoipTelemetry(
      isActive: map['isActive'] as bool? ?? false,
      callId: map['callId'] as String? ?? '',
      callDurationSec: map['callDurationSec'] as int? ?? 0,
      bitrateKbps: (map['bitrateKbps'] as num?)?.toDouble() ?? 0.0,
      packetLossPercent: (map['packetLossPercent'] as num?)?.toDouble() ?? 0.0,
      jitterMs: (map['jitterMs'] as num?)?.toDouble() ?? 0.0,
      mosScore: (map['mosScore'] as num?)?.toDouble() ?? 4.40,
      cipher: map['cipher'] as String? ?? 'SRTP-AES256',
      audioCodec: map['audioCodec'] as String? ?? 'OPUS-HD',
      isMuted: map['isMuted'] as bool? ?? false,
      isSpeakerOn: map['isSpeakerOn'] as bool? ?? false,
      isRecording: map['isRecording'] as bool? ?? false,
      waveforms: waveformsList,
      timestamp:
          map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  VoipTelemetry copyWith({
    bool? isActive,
    String? callId,
    int? callDurationSec,
    double? bitrateKbps,
    double? packetLossPercent,
    double? jitterMs,
    double? mosScore,
    String? cipher,
    String? audioCodec,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isRecording,
    List<double>? waveforms,
    int? timestamp,
  }) {
    return VoipTelemetry(
      isActive: isActive ?? this.isActive,
      callId: callId ?? this.callId,
      callDurationSec: callDurationSec ?? this.callDurationSec,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      packetLossPercent: packetLossPercent ?? this.packetLossPercent,
      jitterMs: jitterMs ?? this.jitterMs,
      mosScore: mosScore ?? this.mosScore,
      cipher: cipher ?? this.cipher,
      audioCodec: audioCodec ?? this.audioCodec,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isRecording: isRecording ?? this.isRecording,
      waveforms: waveforms ?? this.waveforms,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    isActive,
    callId,
    callDurationSec,
    bitrateKbps,
    packetLossPercent,
    jitterMs,
    mosScore,
    cipher,
    audioCodec,
    isMuted,
    isSpeakerOn,
    isRecording,
    waveforms,
    timestamp,
  ];
}
