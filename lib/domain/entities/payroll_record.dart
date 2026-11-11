import 'package:equatable/equatable.dart';

class PayrollRecord extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final String role;
  final double baseSalaryUsd;
  final double sprintBonusUsd;
  final double overtimeHours;
  final double overtimeRateMultiplier;
  final double overtimePayUsd;
  final double incomeTaxUsd;
  final double providentFundUsd;
  final double eobiContributionUsd;
  final double effectiveTaxRate; // e.g. 15.2%
  final String taxJurisdiction; // 'FBR_PKR' or 'FEDERAL_USD'
  final double netPayableUsd;
  final String status; // 'Pending', 'Disbursed'
  final DateTime? disbursedAt;
  final String monthYear;

  const PayrollRecord({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.role,
    required this.baseSalaryUsd,
    required this.sprintBonusUsd,
    required this.overtimeHours,
    required this.overtimeRateMultiplier,
    required this.overtimePayUsd,
    required this.incomeTaxUsd,
    required this.providentFundUsd,
    this.eobiContributionUsd = 1.33,
    this.effectiveTaxRate = 15.0,
    this.taxJurisdiction = 'FBR_PKR',
    required this.netPayableUsd,
    required this.status,
    this.disbursedAt,
    required this.monthYear,
  });

  double get grossEarningsUsd =>
      baseSalaryUsd + sprintBonusUsd + overtimePayUsd;
  double get totalDeductionsUsd =>
      incomeTaxUsd + providentFundUsd + eobiContributionUsd;

  PayrollRecord copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? department,
    String? role,
    double? baseSalaryUsd,
    double? sprintBonusUsd,
    double? overtimeHours,
    double? overtimeRateMultiplier,
    double? overtimePayUsd,
    double? incomeTaxUsd,
    double? providentFundUsd,
    double? eobiContributionUsd,
    double? effectiveTaxRate,
    String? taxJurisdiction,
    double? netPayableUsd,
    String? status,
    DateTime? disbursedAt,
    String? monthYear,
  }) {
    return PayrollRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      role: role ?? this.role,
      baseSalaryUsd: baseSalaryUsd ?? this.baseSalaryUsd,
      sprintBonusUsd: sprintBonusUsd ?? this.sprintBonusUsd,
      overtimeHours: overtimeHours ?? this.overtimeHours,
      overtimeRateMultiplier:
          overtimeRateMultiplier ?? this.overtimeRateMultiplier,
      overtimePayUsd: overtimePayUsd ?? this.overtimePayUsd,
      incomeTaxUsd: incomeTaxUsd ?? this.incomeTaxUsd,
      providentFundUsd: providentFundUsd ?? this.providentFundUsd,
      eobiContributionUsd: eobiContributionUsd ?? this.eobiContributionUsd,
      effectiveTaxRate: effectiveTaxRate ?? this.effectiveTaxRate,
      taxJurisdiction: taxJurisdiction ?? this.taxJurisdiction,
      netPayableUsd: netPayableUsd ?? this.netPayableUsd,
      status: status ?? this.status,
      disbursedAt: disbursedAt ?? this.disbursedAt,
      monthYear: monthYear ?? this.monthYear,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    department,
    role,
    baseSalaryUsd,
    sprintBonusUsd,
    overtimeHours,
    overtimeRateMultiplier,
    overtimePayUsd,
    incomeTaxUsd,
    providentFundUsd,
    eobiContributionUsd,
    effectiveTaxRate,
    taxJurisdiction,
    netPayableUsd,
    status,
    disbursedAt,
    monthYear,
  ];
}
