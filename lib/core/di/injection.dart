import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local/app_database.dart';
import '../../data/datasources/native/voip_native_bridge.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/dispatch_repository_impl.dart';
import '../../data/repositories/geofence_repository_impl.dart';
import '../../data/repositories/payroll_repository_impl.dart';
import '../../data/repositories/voip_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/dispatch_repository.dart';
import '../../domain/repositories/geofence_repository.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../domain/repositories/voip_repository.dart';
import '../../presentation/ai_copilot/cubit/ai_copilot_cubit.dart';
import '../../presentation/attendance/bloc/attendance_bloc.dart';
import '../../presentation/payroll/bloc/payroll_bloc.dart';
import '../../presentation/tracking/bloc/dispatch_bloc.dart';
import '../../presentation/voip/bloc/voip_bloc.dart';
import '../theme/theme_cubit.dart';

final getIt = GetIt.instance;

Future<void> initDependencies({SharedPreferences? prefs}) async {
  if (prefs != null) {
    if (!getIt.isRegistered<SharedPreferences>()) {
      getIt.registerSingleton<SharedPreferences>(prefs);
    }
  }

  if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerLazySingleton<AppDatabase>(() => AppDatabase());
  }

  if (!getIt.isRegistered<VoipNativeBridge>()) {
    getIt.registerLazySingleton<VoipNativeBridge>(() => VoipNativeBridge());
  }

  if (!getIt.isRegistered<AttendanceRepository>()) {
    getIt.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<PayrollRepository>()) {
    getIt.registerLazySingleton<PayrollRepository>(
      () => PayrollRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<DispatchRepository>()) {
    getIt.registerLazySingleton<DispatchRepository>(
      () => DispatchRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<GeofenceRepository>()) {
    getIt.registerLazySingleton<GeofenceRepository>(
      () => GeofenceRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  if (!getIt.isRegistered<VoipRepository>()) {
    getIt.registerLazySingleton<VoipRepository>(
      () => VoipRepositoryImpl(getIt<AppDatabase>(), getIt<VoipNativeBridge>()),
    );
  }

  if (!getIt.isRegistered<ThemeCubit>()) {
    getIt.registerFactory<ThemeCubit>(
      () => ThemeCubit(
        getIt.isRegistered<SharedPreferences>()
            ? getIt<SharedPreferences>()
            : null,
      ),
    );
  }

  if (!getIt.isRegistered<AttendanceBloc>()) {
    getIt.registerFactory<AttendanceBloc>(
      () => AttendanceBloc(
        getIt<AttendanceRepository>(),
        getIt<GeofenceRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<PayrollBloc>()) {
    getIt.registerFactory<PayrollBloc>(
      () => PayrollBloc(getIt<PayrollRepository>()),
    );
  }

  if (!getIt.isRegistered<DispatchBloc>()) {
    getIt.registerFactory<DispatchBloc>(
      () => DispatchBloc(
        getIt<DispatchRepository>(),
        getIt<GeofenceRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<VoipBloc>()) {
    getIt.registerFactory<VoipBloc>(() => VoipBloc(getIt<VoipRepository>()));
  }

  if (!getIt.isRegistered<AiCopilotCubit>()) {
    getIt.registerFactory<AiCopilotCubit>(
      () => AiCopilotCubit(getIt<AppDatabase>()),
    );
  }
}
