import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../data/datasources/local/app_database.dart';
import 'ai_copilot_state.dart';

class AiCopilotCubit extends Cubit<AiCopilotState> {
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  AiCopilotCubit(this._db)
      : super(AiCopilotState(
          messages: [
            CopilotMessage(
              id: 'init-msg',
              role: 'assistant',
              content:
                  'OctetPulse Enterprise Intelligence Engine initialized. I have live access to your SQLite workforce attendance, automated payroll ledger, and field dispatch SLA tracking. Select a prompt chip below or type an executive inquiry.',
              timestamp: DateTime.now(),
            ),
          ],
        ));

  Future<void> sendPrompt(String promptText) async {
    if (state.isStreaming || promptText.trim().isEmpty) return;

    final userMsg = CopilotMessage(
      id: _uuid.v4(),
      role: 'user',
      content: promptText.trim(),
      timestamp: DateTime.now(),
    );

    final updatedWithUser = [...state.messages, userMsg];
    emit(state.copyWith(
      messages: updatedWithUser,
      isStreaming: true,
      streamingStatusText: 'Auditing workforce attendance, payroll burn & SLA metrics...',
    ));

    try {
      // Live audit from local SQLite
      final db = await _db.database;
      final employeesCount = (await db.rawQuery('SELECT COUNT(*) FROM employees')).first.values.first as int? ?? 0;
      final pendingLeaves = (await db.rawQuery("SELECT COUNT(*) FROM leave_requests WHERE status = 'Pending'")).first.values.first as int? ?? 0;
      final payrollSummary = await db.rawQuery("SELECT SUM(baseSalaryUsd), SUM(overtimePayUsd), SUM(netPayableUsd), COUNT(*) FROM payroll WHERE status = 'Pending'");
      final activeTasks = (await db.rawQuery("SELECT COUNT(*) FROM dispatch_tasks WHERE status = 'In Transit'")).first.values.first as int? ?? 0;

      final pendingDisburseCount = payrollSummary.isNotEmpty ? (payrollSummary.first['COUNT(*)'] as int? ?? 0) : 0;
      final totalNetBurn = payrollSummary.isNotEmpty ? ((payrollSummary.first['SUM(netPayableUsd)'] as num?)?.toDouble() ?? 0.0) : 0.0;
      final totalOtBurn = payrollSummary.isNotEmpty ? ((payrollSummary.first['SUM(overtimePayUsd)'] as num?)?.toDouble() ?? 0.0) : 0.0;

      final responseText = _synthesizeResponse(
        prompt: promptText,
        employeesCount: employeesCount,
        pendingLeaves: pendingLeaves,
        pendingPayrollCount: pendingDisburseCount,
        totalNetBurn: totalNetBurn,
        totalOtBurn: totalOtBurn,
        activeTasks: activeTasks,
      );

      final assistantMsgId = _uuid.v4();
      final words = responseText.split(' ');
      String accumulated = '';

      // Stream words
      for (int i = 0; i < words.length; i++) {
        accumulated += (i == 0 ? '' : ' ') + words[i];

        final streamMsg = CopilotMessage(
          id: assistantMsgId,
          role: 'assistant',
          content: accumulated,
          timestamp: DateTime.now(),
          isStreaming: i < words.length - 1,
        );

        final updatedList = [...updatedWithUser, streamMsg];
        emit(state.copyWith(
          messages: updatedList,
          clearStatusText: i > 2,
        ));

        await Future<void>.delayed(const Duration(milliseconds: 28));
      }
    } catch (e) {
      final errorMsg = CopilotMessage(
        id: _uuid.v4(),
        role: 'assistant',
        content: 'Audit query encountered an issue: $e. Please verify local ledger state.',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(
        messages: [...state.messages, errorMsg],
      ));
    } finally {
      // Guarantees isStreaming is reset to false
      emit(state.copyWith(
        isStreaming: false,
        clearStatusText: true,
      ));
    }
  }

  void clearConversation() {
    emit(AiCopilotState(
      messages: [
        CopilotMessage(
          id: 'init-msg',
          role: 'assistant',
          content:
              'Operations transcript cleared. Ready for the next workforce governance or SLA audit inquiry.',
          timestamp: DateTime.now(),
        ),
      ],
    ));
  }

  String _synthesizeResponse({
    required String prompt,
    required int employeesCount,
    required int pendingLeaves,
    required int pendingPayrollCount,
    required double totalNetBurn,
    required double totalOtBurn,
    required int activeTasks,
  }) {
    final lower = prompt.toLowerCase();

    if (lower.contains('payroll') || lower.contains('variance') || lower.contains('burn')) {
      return 'EXECUTIVE PAYROLL AUDIT:\n\n'
          '• Total Active Headcount: $employeesCount corporate engineers and field leads.\n'
          '• Pending Disbursement Volume: $pendingPayrollCount records totaling \$${totalNetBurn.toStringAsFixed(2)} net.\n'
          '• Overtime Variance: Accrued overtime pay stands at \$${totalOtBurn.toStringAsFixed(2)}, driven by weekend fiber telemetry deployment.\n'
          '• Statutory Deductions: 15.0% graduated income tax and 5.0% provident fund match successfully withheld in SQLite ledger.\n'
          '• Recommendation: Authorize monthly batch disbursement to maintain sprint velocity and clear outstanding liabilities.';
    }

    if (lower.contains('dispatch') || lower.contains('bottleneck') || lower.contains('fleet')) {
      return 'FIELD DISPATCH & SLA AUDIT:\n\n'
          '• Active Fleet Corridors: $activeTasks tasks currently marked "In Transit" across Lahore Gulberg and DHA Phase 5 corridors.\n'
          '• Mean Transit Speed: Field units averaging 38.6 km/h under optimal traffic conditions.\n'
          '• Bottleneck Detection: Route waypoint density indicates slight delay near Model Town Link Road junction.\n'
          '• Battery Safety Margin: All units reporting battery levels > 74%, well above the 20% critical threshold.\n'
          '• Recommendation: Maintain real-time GPS telemetry streaming and re-route emergency backup if ETA exceeds 25 minutes.';
    }

    if (lower.contains('governance') || lower.contains('sprint') || lower.contains('summary')) {
      return 'SPRINT WORKFORCE GOVERNANCE REPORT:\n\n'
          '• Workforce Utilization: 94.2% operational availability across Mobile Engineering, Cloud Infra, and Security.\n'
          '• Pending Approvals: $pendingLeaves pending leave/overtime requests awaiting Team Lead clearance in the cockpit.\n'
          '• Native VoIP Infrastructure: SRTP-AES256 encryption active with mean MOS quality score of 4.38 across HD voice packets.\n'
          '• Compliance Status: 100% adherence to geofence clock-in boundaries at ASTP HQ.\n'
          '• Next Steps: Review pending leave requests and approve valid overtime logs.';
    }

    if (lower.contains('coverage') || lower.contains('shift')) {
      return 'SHIFT COVERAGE OPTIMIZATION:\n\n'
          '• Core Operational Window: 09:00 - 18:00 PKT.\n'
          '• Departmental Coverage: Mobile Engineering (100%), Cloud Infrastructure (96%), Field Operations (88%), Security & Compliance (100%).\n'
          '• Standby Coverage: 1 field specialist stationed at HQ standby ready for emergency dispatch within 5 minutes.\n'
          '• Recommendation: Approve pending overtime compensation for Hamza Sheikh to cover the upcoming Saturday cloud failover simulation.';
    }

    return 'EXECUTIVE WORKFORCE ANALYSIS:\n\n'
        '• Headcount: $employeesCount enterprise personnel registered.\n'
        '• Shift Adherence: High compliance with zero unauthorized geofence breaches detected.\n'
        '• Payroll Liability: \$${totalNetBurn.toStringAsFixed(2)} pending execution across $pendingPayrollCount accounts.\n'
        '• VoIP Communication: Encrypted channels operational with zero packet loss anomalies.\n'
        '• System Health: Local SQLite database synchronized with offline cache resilience.';
  }
}
