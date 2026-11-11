import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../entities/voip_recording.dart';

class TranscriptSimulator {
  static final Random _random = Random();

  static VoipRecording simulateRecording({
    required String recordingId,
    required String callId,
    required String calleeId,
    required String calleeName,
    required String calleeRole,
    required int durationSeconds,
    DateTime? recordedAt,
  }) {
    final timestamp = recordedAt ?? DateTime.now();
    final effectiveDuration = durationSeconds > 0 ? durationSeconds : 45;

    final tokens = _generateTranscriptTokens(
      calleeName: calleeName,
      calleeRole: calleeRole,
      durationSeconds: effectiveDuration,
    );

    final waveforms = _generateWaveforms(effectiveDuration);

    final fileSizeBytes = (effectiveDuration * 16000 * 0.45).round();
    final filePath =
        '/data/user/0/com.safeer.octetpulse/vault/rec_${recordingId.toLowerCase()}.opus.aes';

    final rawDigestPayload =
        '$recordingId:$callId:$calleeId:${timestamp.toIso8601String()}:$fileSizeBytes';
    final checksum = sha256.convert(utf8.encode(rawDigestPayload)).toString();

    return VoipRecording(
      id: recordingId,
      callId: callId,
      calleeId: calleeId,
      calleeName: calleeName,
      calleeRole: calleeRole,
      recordedAt: timestamp,
      durationSeconds: effectiveDuration,
      fileSizeBytes: fileSizeBytes,
      filePath: filePath,
      cipher: 'AES-256-GCM',
      checksumSha256: checksum,
      waveforms: waveforms,
      transcript: tokens,
    );
  }

  static List<TranscriptToken> _generateTranscriptTokens({
    required String calleeName,
    required String calleeRole,
    required int durationSeconds,
  }) {
    final List<TranscriptToken> tokens = [];
    final speaker1 = 'Coordinator';
    final speaker2 = calleeName.split(' ').first;

    if (calleeName.toLowerCase().contains('zainab') ||
        calleeRole.toLowerCase().contains('flutter') ||
        calleeRole.toLowerCase().contains('mobile')) {
      tokens.add(
        TranscriptToken(
          offsetMs: 1200,
          speaker: speaker1,
          text: 'Zainab, confirming status on Sprint 3 audio recording bridge and Android SDK 36 verification.',
          confidence: 0.99,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 4800,
          speaker: speaker2,
          text: 'Native Kotlin and Swift control channels are operational. AES-256 GCM metadata ledger is connected.',
          confidence: 0.98,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 9500,
          speaker: speaker1,
          text: 'Good. Make sure the waveform scrubber supports 800x360 landscape viewport with zero overflow.',
          confidence: 0.97,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 15200,
          speaker: speaker2,
          text: 'Verified. Master-detail two-pane layout with independent scroll controllers is running cleanly.',
          confidence: 0.99,
        ),
      );
    } else if (calleeName.toLowerCase().contains('tariq') ||
        calleeRole.toLowerCase().contains('operations') ||
        calleeRole.toLowerCase().contains('field')) {
      tokens.add(
        TranscriptToken(
          offsetMs: 1500,
          speaker: speaker1,
          text: 'Tariq, dispatch reports active field units are traversing near the ASTP HQ polygon boundary.',
          confidence: 0.98,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 5200,
          speaker: speaker2,
          text: 'Ray-Casting algorithm confirms all 5 units are contained within the designated campus perimeter.',
          confidence: 0.99,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 10400,
          speaker: speaker1,
          text: 'Excellent. Automatic attendance clock-in triggers are calibrated for zero false positives.',
          confidence: 0.98,
        ),
      );
    } else {
      tokens.add(
        TranscriptToken(
          offsetMs: 1000,
          speaker: speaker1,
          text: 'Secure encrypted connection established. Running enterprise SLA telemetry audit.',
          confidence: 0.98,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 4500,
          speaker: speaker2,
          text: 'Telemetry received with 4.41 MOS score and sub-5ms jitter across OPUS-HD stream.',
          confidence: 0.99,
        ),
      );
      tokens.add(
        TranscriptToken(
          offsetMs: 9200,
          speaker: speaker1,
          text: 'Proceeding with scheduled daily sprint deliverables and encrypted ledger synchronization.',
          confidence: 0.97,
        ),
      );
    }

    if (durationSeconds > 25) {
      tokens.add(
        TranscriptToken(
          offsetMs: 22000,
          speaker: speaker2,
          text: 'Call session audit log sealed with SHA-256 fingerprint and saved to encrypted vault.',
          confidence: 0.99,
        ),
      );
    }

    return tokens;
  }

  static List<double> _generateWaveforms(int durationSeconds) {
    const pointCount = 32;
    final List<double> points = [];
    for (int i = 0; i < pointCount; i++) {
      final base = 0.20 + (_random.nextDouble() * 0.70);
      points.add(double.parse(base.toStringAsFixed(2)));
    }
    return points;
  }
}
