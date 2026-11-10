import 'package:equatable/equatable.dart';
import '../../../domain/entities/payroll_record.dart';

abstract class PayrollEvent extends Equatable {
  const PayrollEvent();

  @override
  List<Object?> get props => [];
}

class LoadPayrollData extends PayrollEvent {
  const LoadPayrollData();
}

class RunPayrollBatchEvent extends PayrollEvent {
  final String monthYear;

  const RunPayrollBatchEvent({required this.monthYear});

  @override
  List<Object?> get props => [monthYear];
}

class DisbursePayrollEvent extends PayrollEvent {
  final String recordId;

  const DisbursePayrollEvent({required this.recordId});

  @override
  List<Object?> get props => [recordId];
}

class ToggleCurrencyEvent extends PayrollEvent {
  const ToggleCurrencyEvent();
}

class SelectPayrollRecordEvent extends PayrollEvent {
  final PayrollRecord? record;

  const SelectPayrollRecordEvent(this.record);

  @override
  List<Object?> get props => [record];
}
