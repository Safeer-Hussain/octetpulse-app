import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'presentation/ai_copilot/cubit/ai_copilot_cubit.dart';
import 'presentation/attendance/bloc/attendance_bloc.dart';
import 'presentation/attendance/bloc/attendance_event.dart';
import 'presentation/payroll/bloc/payroll_bloc.dart';
import 'presentation/payroll/bloc/payroll_event.dart';
import 'presentation/splash/splash_view.dart';
import 'presentation/tracking/bloc/dispatch_bloc.dart';
import 'presentation/tracking/bloc/dispatch_event.dart';
import 'presentation/voip/bloc/voip_bloc.dart';
import 'presentation/voip/bloc/voip_event.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (_) {}

      await initDependencies(prefs: prefs);

      runApp(const OctetPulseApp());
    },
    (error, stack) {
      // Unhandled defensive error logger
    },
  );
}

class OctetPulseApp extends StatelessWidget {
  const OctetPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => getIt<ThemeCubit>()),
        BlocProvider<AttendanceBloc>(
          create: (_) =>
              getIt<AttendanceBloc>()..add(const LoadAttendanceData()),
        ),
        BlocProvider<PayrollBloc>(
          create: (_) => getIt<PayrollBloc>()..add(const LoadPayrollData()),
        ),
        BlocProvider<DispatchBloc>(
          create: (_) => getIt<DispatchBloc>()..add(const LoadDispatchData()),
        ),
        BlocProvider<VoipBloc>(
          create: (_) =>
              getIt<VoipBloc>()..add(const LoadVoipDirectoryAndLogs()),
        ),
        BlocProvider<AiCopilotCubit>(create: (_) => getIt<AiCopilotCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: const SplashView(),
          );
        },
      ),
    );
  }
}
