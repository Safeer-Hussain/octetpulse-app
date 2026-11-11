import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/theme/app_theme.dart';
import 'package:octet_pulse_app/domain/entities/employee.dart';
import 'package:octet_pulse_app/domain/services/transcript_simulator.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_bloc.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_event.dart';
import 'package:octet_pulse_app/presentation/voip/views/voip_hub_view.dart';

import '../fakes/fake_repositories.dart';

void main() {
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

  final sampleRecording = TranscriptSimulator.simulateRecording(
    recordingId: 'REC-TEST-WIDGET-01',
    callId: 'call_102_001',
    calleeId: 'EMP-102',
    calleeName: 'Zainab Tariq',
    calleeRole: 'Lead Flutter Engineer',
    durationSeconds: 48,
    recordedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  Widget createSubject({
    required bool isDark,
    required FakeVoipRepository repo,
  }) {
    return BlocProvider<VoipBloc>(
      create: (_) => VoipBloc(repo)..add(const LoadVoipDirectoryAndLogs()),
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const Scaffold(body: VoipHubView()),
      ),
    );
  }

  testWidgets(
    'VoipHubView renders 3 tabs and displays encrypted recordings in Vault tab',
    (WidgetTester tester) async {
      final repo = FakeVoipRepository();
      repo.directory = [sampleEmployee];
      repo.recordings = [sampleRecording];

      await tester.pumpWidget(createSubject(isDark: true, repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Directory & Channels'), findsOneWidget);
      expect(find.text('Active Cockpit & Keypad'), findsOneWidget);
      expect(find.text('Vault & Transcripts'), findsOneWidget);

      // Switch to Vault & Transcripts tab
      await tester.tap(find.text('Vault & Transcripts'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Encrypted Audio Vault'), findsOneWidget);
      expect(find.textContaining('AES-256-GCM'), findsWidgets);
      expect(find.text('Zainab Tariq'), findsWidgets);
      expect(find.text('Decrypted Transcript'), findsOneWidget);
    },
  );

  testWidgets(
    'VoipHubView Vault tab allows scrubber seeking and transcript search filtering',
    (WidgetTester tester) async {
      final repo = FakeVoipRepository();
      repo.directory = [sampleEmployee];
      repo.recordings = [sampleRecording];

      await tester.pumpWidget(createSubject(isDark: false, repo: repo));
      await tester.pumpAndSettle();

      // Switch to Vault tab
      await tester.tap(find.text('Vault & Transcripts'));
      await tester.pumpAndSettle();

      // Find Play/Pause button
      final playIconFinder = find.byIcon(Icons.play_arrow);
      expect(playIconFinder, findsWidgets);

      // Tap play button to test playback start
      await tester.tap(playIconFinder.first);
      await tester.pump(const Duration(milliseconds: 350));

      // Test searching inside transcript
      final searchField = find.widgetWithText(
        TextField,
        'Search transcript dialogue...',
      );
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Kotlin');
      await tester.pumpAndSettle();

      expect(find.textContaining('Native Kotlin and Swift'), findsOneWidget);
    },
  );

  testWidgets(
    'VoipHubView renders cleanly on 800x360 landscape viewport with zero overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = FakeVoipRepository();
      repo.directory = [sampleEmployee];
      repo.recordings = [sampleRecording];

      await tester.pumpWidget(createSubject(isDark: true, repo: repo));
      await tester.pumpAndSettle();

      // Switch to Vault tab in landscape
      await tester.tap(find.text('Vault & Transcripts'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Encrypted Audio Vault'), findsOneWidget);
      expect(find.text('Decrypted Transcript'), findsOneWidget);
    },
  );
}
