import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/app_feedback.dart';
import '../../attendance/bloc/attendance_bloc.dart';
import '../../attendance/bloc/attendance_event.dart';
import '../../payroll/bloc/payroll_bloc.dart';
import '../../payroll/bloc/payroll_event.dart';
import '../../tracking/bloc/dispatch_bloc.dart';
import '../../tracking/bloc/dispatch_event.dart';
import '../../voip/bloc/voip_bloc.dart';
import '../../voip/bloc/voip_event.dart';

class RecruiterDebugDrawer extends StatefulWidget {
  const RecruiterDebugDrawer({super.key});

  @override
  State<RecruiterDebugDrawer> createState() => _RecruiterDebugDrawerState();
}

class _RecruiterDebugDrawerState extends State<RecruiterDebugDrawer> {
  late SharedPreferences _prefs;
  double _latencyMs = 450.0;
  bool _force503 = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() {
    if (getIt.isRegistered<SharedPreferences>()) {
      _prefs = getIt<SharedPreferences>();
      _latencyMs = (_prefs.getInt(AppConstants.prefSimulatedLatencyMs) ?? 450)
          .toDouble();
      _force503 = _prefs.getBool(AppConstants.prefForce503Error) ?? false;
      setState(() {
        _initialized = true;
      });
    }
  }

  void _updateLatency(double value) {
    setState(() {
      _latencyMs = value;
    });
    _prefs.setInt(AppConstants.prefSimulatedLatencyMs, value.toInt());
  }

  void _toggle503(bool value) {
    setState(() {
      _force503 = value;
    });
    _prefs.setBool(AppConstants.prefForce503Error, value);
    if (value) {
      AppFeedback.showWarning(context, 'Simulated HTTP 503 error activated.');
    } else {
      AppFeedback.showSuccess(
        context,
        'HTTP 503 error deactivated. Network normal.',
      );
    }
  }

  void _simulateIncomingVoipCall() {
    context.read<VoipBloc>().add(
      const InitiateVoipCallEvent(
        calleeId: 'EMP-116',
        calleeName: 'Shahmeer Khan',
        calleeRole: 'Chief Security Officer',
      ),
    );
    Navigator.of(context).pop();
    AppFeedback.showInfo(
      context,
      'Simulated incoming call connected with CSO Shahmeer Khan.',
    );
  }

  void _reloadAllBlocs() {
    context.read<AttendanceBloc>().add(const LoadAttendanceData());
    context.read<PayrollBloc>().add(const LoadPayrollData());
    context.read<DispatchBloc>().add(const LoadDispatchData());
    context.read<VoipBloc>().add(const LoadVoipDirectoryAndLogs());
    AppFeedback.showSuccess(
      context,
      'All workforce BLoC state engines re-synchronized.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: _initialized
            ? ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Recruiter Debug Console',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Evaluate offline resilience, latency handling, and real-time VoIP telemetry without external APIs.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colorScheme.outlineVariant),
                  const SizedBox(height: 12),
                  Text(
                    'SIMULATED NETWORK LATENCY: ${_latencyMs.toInt()} ms',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: colorScheme.primary,
                    ),
                  ),
                  Slider(
                    value: _latencyMs,
                    min: 400.0,
                    max: 850.0,
                    divisions: 9,
                    label: '${_latencyMs.toInt()} ms',
                    activeColor: colorScheme.primary,
                    onChanged: _updateLatency,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: colorScheme.surfaceContainer,
                    child: SwitchListTile(
                      title: Text(
                        'Simulate HTTP 503 Outage',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Forces badResponse on mock interceptor to verify error retry views.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _force503,
                      activeTrackColor: colorScheme.error,
                      onChanged: _toggle503,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: colorScheme.surfaceContainer,
                    child: ListTile(
                      leading: Icon(
                        Icons.phone_in_talk,
                        color: colorScheme.secondary,
                      ),
                      title: Text(
                        'Simulate Incoming VoIP Call',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Trigger encrypted call with CSO Shahmeer Khan & mount native telemetry.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: _simulateIncomingVoipCall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: colorScheme.surfaceContainer,
                    child: ListTile(
                      leading: Icon(Icons.sync, color: colorScheme.tertiary),
                      title: Text(
                        'Re-sync SQLite Workforce Ledger',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Reload attendance, payroll batch, and fleet GPS states.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: _reloadAllBlocs,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SYSTEM ARCHITECTURE INFO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Platform: Flutter 3.47 + Dart 3.13\nAndroid SDK: 36 (target/compile)\nState: flutter_bloc 9.x + GetIt\nLedger: SQLite on-device\nVoIP: Native Method/EventChannel',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
