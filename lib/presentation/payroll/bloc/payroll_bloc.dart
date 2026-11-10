import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/payroll_repository.dart';
import 'payroll_event.dart';
import 'payroll_state.dart';

class PayrollBloc extends Bloc<PayrollEvent, PayrollState> {
  final PayrollRepository _repository;

  PayrollBloc(this._repository) : super(const PayrollState()) {
    on<LoadPayrollData>(_onLoadPayrollData);
    on<RunPayrollBatchEvent>(_onRunPayrollBatch);
    on<DisbursePayrollEvent>(_onDisbursePayroll);
    on<ToggleCurrencyEvent>(_onToggleCurrency);
    on<SelectPayrollRecordEvent>(_onSelectPayrollRecord);
  }

  Future<void> _onLoadPayrollData(
    LoadPayrollData event,
    Emitter<PayrollState> emit,
  ) async {
    emit(state.copyWith(status: PayrollStatusState.loading));
    try {
      final records = await _repository.getPayrollRecords();
      emit(state.copyWith(status: PayrollStatusState.loaded, records: records));
    } catch (e) {
      emit(
        state.copyWith(
          status: PayrollStatusState.error,
          errorMessage: 'Failed to load payroll: $e',
        ),
      );
    }
  }

  Future<void> _onRunPayrollBatch(
    RunPayrollBatchEvent event,
    Emitter<PayrollState> emit,
  ) async {
    emit(state.copyWith(status: PayrollStatusState.loading));
    try {
      await _repository.runPayrollBatch(monthYear: event.monthYear);
      final refreshed = await _repository.getPayrollRecords();
      emit(
        state.copyWith(
          status: PayrollStatusState.loaded,
          records: refreshed,
          currentMonthYear: event.monthYear,
          feedbackMessage:
              'Payroll batch for ${event.monthYear} executed across ${refreshed.length} employees.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PayrollStatusState.error,
          errorMessage: 'Batch run failed: $e',
        ),
      );
    }
  }

  Future<void> _onDisbursePayroll(
    DisbursePayrollEvent event,
    Emitter<PayrollState> emit,
  ) async {
    try {
      final disbursed = await _repository.disbursePayroll(
        recordId: event.recordId,
      );
      final updatedRecords = state.records
          .map((r) => r.id == disbursed.id ? disbursed : r)
          .toList();

      emit(
        state.copyWith(
          records: updatedRecords,
          selectedRecord: state.selectedRecord?.id == disbursed.id
              ? disbursed
              : state.selectedRecord,
          feedbackMessage:
              'Payslip #${disbursed.id} disbursed to ${disbursed.employeeName}.',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Disbursement failed: $e'));
    }
  }

  void _onToggleCurrency(
    ToggleCurrencyEvent event,
    Emitter<PayrollState> emit,
  ) {
    emit(state.copyWith(isUsd: !state.isUsd));
  }

  void _onSelectPayrollRecord(
    SelectPayrollRecordEvent event,
    Emitter<PayrollState> emit,
  ) {
    emit(state.copyWith(selectedRecord: event.record));
  }
}
