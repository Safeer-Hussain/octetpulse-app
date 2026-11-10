import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/theme/app_theme.dart';
import 'package:octet_pulse_app/core/theme/theme_cubit.dart';
import 'package:octet_pulse_app/presentation/ai_copilot/cubit/ai_copilot_cubit.dart';
import 'package:octet_pulse_app/presentation/attendance/bloc/attendance_bloc.dart';
import 'package:octet_pulse_app/presentation/payroll/bloc/payroll_bloc.dart';
import 'package:octet_pulse_app/presentation/shell/adaptive_scaffold.dart';
import 'package:octet_pulse_app/presentation/tracking/bloc/dispatch_bloc.dart';
import 'package:octet_pulse_app/presentation/voip/bloc/voip_bloc.dart';

import 'fakes/fake_repositories.dart';
import 'unit/ai_copilot_cubit_test.dart';

void main() {
  testWidgets('AdaptiveScaffold renders cleanly without Hero collisions', (
    WidgetTester tester,
  ) async {
    final fakeAttendance = FakeAttendanceRepository();
    final fakePayroll = FakePayrollRepository();
    final fakeVoip = FakeVoipRepository();
    final fakeDispatch = FakeDispatchRepository();
    final mockDb = MockAppDatabase();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
          BlocProvider<AttendanceBloc>(
            create: (_) => AttendanceBloc(fakeAttendance),
          ),
          BlocProvider<PayrollBloc>(create: (_) => PayrollBloc(fakePayroll)),
          BlocProvider<DispatchBloc>(create: (_) => DispatchBloc(fakeDispatch)),
          BlocProvider<VoipBloc>(create: (_) => VoipBloc(fakeVoip)),
          BlocProvider<AiCopilotCubit>(create: (_) => AiCopilotCubit(mockDb)),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const AdaptiveScaffold(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(AdaptiveScaffold), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('AdaptiveScaffold switches Dark to Light theme immediately', (
    WidgetTester tester,
  ) async {
    final fakeAttendance = FakeAttendanceRepository();
    final fakePayroll = FakePayrollRepository();
    final fakeVoip = FakeVoipRepository();
    final fakeDispatch = FakeDispatchRepository();
    final mockDb = MockAppDatabase();
    final themeCubit = ThemeCubit();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: themeCubit),
          BlocProvider<AttendanceBloc>(
            create: (_) => AttendanceBloc(fakeAttendance),
          ),
          BlocProvider<PayrollBloc>(create: (_) => PayrollBloc(fakePayroll)),
          BlocProvider<DispatchBloc>(create: (_) => DispatchBloc(fakeDispatch)),
          BlocProvider<VoipBloc>(create: (_) => VoipBloc(fakeVoip)),
          BlocProvider<AiCopilotCubit>(create: (_) => AiCopilotCubit(mockDb)),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, mode) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: mode,
              home: const AdaptiveScaffold(),
            );
          },
        ),
      ),
    );

    await tester.pump();
    expect(themeCubit.state, ThemeMode.dark);

    // Tap theme toggle icon
    final themeToggleBtn = find.byTooltip('Toggle Theme');
    expect(themeToggleBtn, findsOneWidget);
    await tester.tap(themeToggleBtn);
    await tester.pump();

    expect(themeCubit.state, ThemeMode.light);
  });

  testWidgets(
    'Landscape 800x360 viewport renders without RenderFlex overflow',
    (WidgetTester tester) async {
      final fakeAttendance = FakeAttendanceRepository();
      final fakePayroll = FakePayrollRepository();
      final fakeVoip = FakeVoipRepository();
      final fakeDispatch = FakeDispatchRepository();
      final mockDb = MockAppDatabase();

      // Set 800x360 landscape resolution
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
            BlocProvider<AttendanceBloc>(
              create: (_) => AttendanceBloc(fakeAttendance),
            ),
            BlocProvider<PayrollBloc>(create: (_) => PayrollBloc(fakePayroll)),
            BlocProvider<DispatchBloc>(
              create: (_) => DispatchBloc(fakeDispatch),
            ),
            BlocProvider<VoipBloc>(create: (_) => VoipBloc(fakeVoip)),
            BlocProvider<AiCopilotCubit>(create: (_) => AiCopilotCubit(mockDb)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const AdaptiveScaffold(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
