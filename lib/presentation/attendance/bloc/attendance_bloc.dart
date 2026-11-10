import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/leave_request.dart';
import '../../../domain/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;
  final Uuid _uuid = const Uuid();

  AttendanceBloc(this._repository) : super(const AttendanceState()) {
    on<LoadAttendanceData>(_onLoadAttendanceData);
    on<ClockInEvent>(_onClockIn);
    on<ToggleBreakEvent>(_onToggleBreak);
    on<ClockOutEvent>(_onClockOut);
    on<SubmitLeaveRequestEvent>(_onSubmitLeaveRequest);
    on<ApproveLeaveRequestEvent>(_onApproveLeaveRequest);
    on<UpdateGeofencePositionEvent>(_onUpdateGeofencePosition);
  }

  Future<void> _onLoadAttendanceData(
    LoadAttendanceData event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStatusState.loading));
    try {
      final latest = await _repository.getLatestAttendanceRecord();
      final history = await _repository.getAttendanceHistory();
      final leaveRequests = await _repository.getLeaveRequests();

      final isCurrentActive =
          latest != null &&
          (latest.status == 'Clocked In' || latest.status == 'On Break');

      emit(
        state.copyWith(
          status: AttendanceStatusState.loaded,
          currentRecord: isCurrentActive ? latest : null,
          history: history,
          leaveRequests: leaveRequests,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatusState.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onClockIn(
    ClockInEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final record = await _repository.clockIn(
        employeeId: event.employeeId,
        employeeName: event.employeeName,
        latitude: event.latitude,
        longitude: event.longitude,
        isWithinGeofence: event.isWithinGeofence,
        geofenceDistanceMeters: event.geofenceDistanceMeters,
      );

      final updatedHistory = [record, ...state.history];
      emit(
        state.copyWith(
          currentRecord: record,
          history: updatedHistory,
          feedbackMessage:
              'Clocked In successfully at ${AppConstants.hqLocationName}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Clock-in failed: $e'));
    }
  }

  Future<void> _onToggleBreak(
    ToggleBreakEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.currentRecord == null) return;
    try {
      final updated = await _repository.toggleBreak(
        recordId: state.currentRecord!.id,
      );
      final updatedHistory = state.history
          .map((r) => r.id == updated.id ? updated : r)
          .toList();

      emit(
        state.copyWith(
          currentRecord: updated,
          history: updatedHistory,
          feedbackMessage: updated.status == 'On Break'
              ? 'Break started.'
              : 'Break ended. Shift resumed.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Break toggle failed: $e'));
    }
  }

  Future<void> _onClockOut(
    ClockOutEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state.currentRecord == null) return;
    try {
      final updated = await _repository.clockOut(
        recordId: state.currentRecord!.id,
      );
      final updatedHistory = state.history
          .map((r) => r.id == updated.id ? updated : r)
          .toList();

      emit(
        state.copyWith(
          clearCurrentRecord: true,
          history: updatedHistory,
          feedbackMessage: 'Clocked Out successfully.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Clock-out failed: $e'));
    }
  }

  Future<void> _onSubmitLeaveRequest(
    SubmitLeaveRequestEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final request = LeaveRequest(
        id: 'LV-${_uuid.v4().substring(0, 6).toUpperCase()}',
        employeeId: event.employeeId,
        employeeName: event.employeeName,
        requestType: event.requestType,
        hours: event.hours,
        reason: event.reason,
        submittedAt: DateTime.now(),
        status: 'Pending',
      );

      final saved = await _repository.submitLeaveRequest(request);
      final updatedRequests = [saved, ...state.leaveRequests];

      emit(
        state.copyWith(
          leaveRequests: updatedRequests,
          feedbackMessage: 'Leave request submitted for team approval.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Leave submission failed: $e'));
    }
  }

  Future<void> _onApproveLeaveRequest(
    ApproveLeaveRequestEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    try {
      final updated = await _repository.updateLeaveRequestStatus(
        requestId: event.requestId,
        status: event.status,
        approverComment: event.comment,
      );

      final updatedRequests = state.leaveRequests
          .map((r) => r.id == updated.id ? updated : r)
          .toList();

      emit(
        state.copyWith(
          leaveRequests: updatedRequests,
          feedbackMessage: 'Request #${updated.id} marked ${updated.status}.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Request approval mutation failed: $e'),
      );
    }
  }

  void _onUpdateGeofencePosition(
    UpdateGeofencePositionEvent event,
    Emitter<AttendanceState> emit,
  ) {
    final distance = _calculateDistanceMeters(
      event.latitude,
      event.longitude,
      AppConstants.hqLatitude,
      AppConstants.hqLongitude,
    );
    final isWithin = distance <= AppConstants.hqGeofenceRadiusMeters;

    emit(
      state.copyWith(
        currentLatitude: event.latitude,
        currentLongitude: event.longitude,
        geofenceDistanceMeters: distance,
        isWithinGeofence: isWithin,
      ),
    );
  }

  double _calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742000 * asin(sqrt(a)); // 2 * R * 1000 meters
  }
}
