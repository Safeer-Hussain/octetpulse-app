import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/theme_cubit.dart';
import '../ai_copilot/views/ai_workforce_copilot_view.dart';
import '../attendance/views/attendance_cockpit_view.dart';
import '../payroll/views/payroll_ledger_view.dart';
import '../settings/views/recruiter_debug_drawer.dart';
import '../tracking/views/field_tracker_view.dart';
import '../voip/views/voip_hub_view.dart';
import 'offline_banner.dart';

class AdaptiveScaffold extends StatefulWidget {
  const AdaptiveScaffold({super.key});

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _destinations = const [
    AttendanceCockpitView(),
    PayrollLedgerView(),
    FieldTrackerView(),
    VoipHubView(),
    AiWorkforceCopilotView(),
  ];

  final List<String> _titles = const [
    'Geofenced Attendance & Shift Cockpit',
    'Automated Payroll & Salary Slips',
    'Field Fleet Real-Time GPS Tracker',
    'Encrypted Enterprise VoIP Hub',
    'On-Device AI Workforce Copilot',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        endDrawer: const RecruiterDebugDrawer(),
        appBar: AppBar(
          toolbarHeight: isLandscape ? 36 : 56,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: isLandscape ? 12 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurface,
                ),
              ),
              if (!isLandscape)
                Text(
                  _titles[_currentIndex],
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: [
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                final isDark = themeMode == ThemeMode.dark;
                return IconButton(
                  iconSize: isLandscape ? 18 : 22,
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                  tooltip: 'Toggle Theme',
                  onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                );
              },
            ),
            GestureDetector(
              onLongPress: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: IconButton(
                iconSize: isLandscape ? 18 : 22,
                icon: const Icon(Icons.bug_report_outlined),
                tooltip: 'Recruiter Debug Console',
                onPressed: () {
                  _scaffoldKey.currentState?.openEndDrawer();
                },
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: isLandscape
                  ? Row(
                      children: [
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: IntrinsicHeight(
                            child: NavigationRail(
                              minWidth: 56,
                              labelType: NavigationRailLabelType.none,
                              backgroundColor: colorScheme.surface,
                              selectedIndex: _currentIndex,
                              onDestinationSelected: (idx) =>
                                  setState(() => _currentIndex = idx),
                              destinations: const [
                                NavigationRailDestination(
                                  icon: Icon(Icons.access_time),
                                  selectedIcon: Icon(Icons.access_time_filled),
                                  label: Text('Attendance'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                  selectedIcon: Icon(
                                    Icons.account_balance_wallet,
                                  ),
                                  label: Text('Payroll'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.location_on_outlined),
                                  selectedIcon: Icon(Icons.location_on),
                                  label: Text('Fleet GPS'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.phone_outlined),
                                  selectedIcon: Icon(Icons.phone),
                                  label: Text('VoIP'),
                                ),
                                NavigationRailDestination(
                                  icon: Icon(Icons.auto_awesome_outlined),
                                  selectedIcon: Icon(Icons.auto_awesome),
                                  label: Text('Copilot'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _destinations[_currentIndex]),
                      ],
                    )
                  : _destinations[_currentIndex],
            ),
          ],
        ),
        bottomNavigationBar: isLandscape
            ? null
            : NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (idx) =>
                    setState(() => _currentIndex = idx),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.access_time),
                    selectedIcon: Icon(Icons.access_time_filled),
                    label: 'Attendance',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet),
                    label: 'Payroll',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.location_on_outlined),
                    selectedIcon: Icon(Icons.location_on),
                    label: 'Fleet GPS',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.phone_outlined),
                    selectedIcon: Icon(Icons.phone),
                    label: 'VoIP Hub',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_awesome_outlined),
                    selectedIcon: Icon(Icons.auto_awesome),
                    label: 'AI Copilot',
                  ),
                ],
              ),
      ),
    );
  }
}
