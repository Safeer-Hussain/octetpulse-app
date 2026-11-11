import 'dart:convert';

import 'package:equatable/equatable.dart';

class TranscriptToken extends Equatable {
  final int offsetMs;
  final String speaker;
  final String text;
  final double confidence;

  const TranscriptToken({
    required this.offsetMs,
    required this.speaker,
    required this.text,
    this.confidence = 0.98,
  });

  String get formattedOffset {
    final totalSec = (offsetMs / 1000).floor();
    final mins = (totalSec ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSec % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  Map<String, dynamic> toMap() {
    return {
      'offsetMs': offsetMs,
      'speaker': speaker,
      'text': text,
      'confidence': confidence,
    };
  }

  factory TranscriptToken.fromMap(Map<String, dynamic> map) {
    return TranscriptToken(
      offsetMs: map['offsetMs'] as int? ?? 0,
      speaker: map['speaker'] as String? ?? 'Caller',
      text: map['text'] as String? ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.98,
    );
  }

  @override
  List<Object?> get props => [offsetMs, speaker, text, confidence];
}

class VoipRecording extends Equatable {
  final String id;
  final String callId;
  final String calleeId;
  final String calleeName;
  final String calleeRole;
  final DateTime recordedAt;
  final int durationSeconds;
  final int fileSizeBytes;
  final String filePath;
  final String cipher;
  final String checksumSha256;
  final List<double> waveforms;
  final List<TranscriptToken> transcript;

  const VoipRecording({
    required this.id,
    required this.callId,
    required this.calleeId,
    required this.calleeName,
    required this.calleeRole,
    required this.recordedAt,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.filePath,
    this.cipher = 'AES-256-GCM',
    required this.checksumSha256,
    this.waveforms = const [],
    this.transcript = const [],
  });

  String get formattedDuration {
    final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get checksumShort {
    if (checksumSha256.length <= 12) return checksumSha256;
    return '${checksumSha256.substring(0, 8)}...${checksumSha256.substring(checksumSha256.length - 4)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'callId': callId,
      'calleeId': calleeId,
      'calleeName': calleeName,
      'calleeRole': calleeRole,
      'recordedAt': recordedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'fileSizeBytes': fileSizeBytes,
      'filePath': filePath,
      'cipher': cipher,
      'checksumSha256': checksumSha256,
      'waveformsJson': jsonEncode(waveforms),
      'transcriptJson': jsonEncode(transcript.map((t) => t.toMap()).toList()),
    };
  }

  factory VoipRecording.fromMap(Map<String, dynamic> map) {
    List<double> parsedWaveforms = [];
    if (map['waveformsJson'] != null) {
      try {
        final decoded = jsonDecode(map['waveformsJson'] as String);
        if (decoded is List) {
          parsedWaveforms = decoded.map((e) => (e as num).toDouble()).toList();
        }
      } catch (_) {}
    }

    List<TranscriptToken> parsedTranscript = [];
    if (map['transcriptJson'] != null) {
      try {
        final decoded = jsonDecode(map['transcriptJson'] as String);
        if (decoded is List) {
          parsedTranscript = decoded
              .map((e) => TranscriptToken.fromMap(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return VoipRecording(
      id: map['id'] as String,
      callId: map['callId'] as String,
      calleeId: map['calleeId'] as String,
      calleeName: map['calleeName'] as String,
      calleeRole: map['calleeRole'] as String,
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
      fileSizeBytes: map['fileSizeBytes'] as int? ?? 0,
      filePath: map['filePath'] as String? ?? '',
      cipher: map['cipher'] as String? ?? 'AES-256-GCM',
      checksumSha256: map['checksumSha256'] as String? ?? '',
      waveforms: parsedWaveforms,
      transcript: parsedTranscript,
    );
  }

  VoipRecording copyWith({
    String? id,
    String? callId,
    String? calleeId,
    String? calleeName,
    String? calleeRole,
    DateTime? recordedAt,
    int? durationSeconds,
    int? fileSizeBytes,
    String? filePath,
    String? cipher,
    String? checksumSha256,
    List<double>? waveforms,
    List<TranscriptToken>? transcript,
  }) {
    return VoipRecording(
      id: id ?? this.id,
      callId: callId ?? this.callId,
      calleeId: calleeId ?? this.calleeId,
      calleeName: calleeName ?? this.calleeName,
      calleeRole: calleeRole ?? this.calleeRole,
      recordedAt: recordedAt ?? this.recordedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      filePath: filePath ?? this.filePath,
      cipher: cipher ?? this.cipher,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      waveforms: waveforms ?? this.waveforms,
      transcript: transcript ?? this.transcript,
    );
  }

  @override
  List<Object?> get props => [
    id,
    callId,
    calleeId,
    calleeName,
    calleeRole,
    recordedAt,
    durationSeconds,
    fileSizeBytes,
    filePath,
    cipher,
    checksumSha256,
    waveforms,
    transcript,
  ];
}
