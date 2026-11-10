import 'package:equatable/equatable.dart';

import '../../../domain/entities/payroll_record.dart';

enum PayrollStatusState { initial, loading, loaded, error }

class PayrollState extends Equatable {
  final PayrollStatusState status;
  final List<PayrollRecord> records;
  final PayrollRecord? selectedRecord;
  final bool isUsd;
  final String currentMonthYear;
  final String? feedbackMessage;
  final String? errorMessage;

  const PayrollState({
    this.status = PayrollStatusState.initial,
    this.records = const [],
    this.selectedRecord,
    this.isUsd = true,
    this.currentMonthYear = 'November 2026',
    this.feedbackMessage,
    this.errorMessage,
  });

  double get totalBaseSalaryUsd =>
      records.fold(0.0, (sum, r) => sum + r.baseSalaryUsd);
  double get totalOvertimePayUsd =>
      records.fold(0.0, (sum, r) => sum + r.overtimePayUsd);
  double get totalSprintBonusUsd =>
      records.fold(0.0, (sum, r) => sum + r.sprintBonusUsd);
  double get totalTaxesUsd =>
      records.fold(0.0, (sum, r) => sum + r.incomeTaxUsd);
  double get totalProvidentFundUsd =>
      records.fold(0.0, (sum, r) => sum + r.providentFundUsd);
  double get totalNetPayableUsd =>
      records.fold(0.0, (sum, r) => sum + r.netPayableUsd);

  int get disbursedCount =>
      records.where((r) => r.status == 'Disbursed').length;
  int get pendingCount => records.where((r) => r.status == 'Pending').length;

  PayrollState copyWith({
    PayrollStatusState? status,
    List<PayrollRecord>? records,
    PayrollRecord? selectedRecord,
    bool clearSelectedRecord = false,
    bool? isUsd,
    String? currentMonthYear,
    String? feedbackMessage,
    String? errorMessage,
  }) {
    return PayrollState(
      status: status ?? this.status,
      records: records ?? this.records,
      selectedRecord: clearSelectedRecord
          ? null
          : (selectedRecord ?? this.selectedRecord),
      isUsd: isUsd ?? this.isUsd,
      currentMonthYear: currentMonthYear ?? this.currentMonthYear,
      feedbackMessage: feedbackMessage,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    records,
    selectedRecord,
    isUsd,
    currentMonthYear,
    feedbackMessage,
    errorMessage,
  ];
}
