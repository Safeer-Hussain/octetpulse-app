import 'package:sqflite/sqflite.dart';

import '../../domain/entities/payroll_record.dart';
import '../../domain/repositories/payroll_repository.dart';
import '../../domain/services/tax_engine.dart';
import '../datasources/local/app_database.dart';

class PayrollRepositoryImpl implements PayrollRepository {
  final AppDatabase _db;

  PayrollRepositoryImpl(this._db);

  @override
  Future<List<PayrollRecord>> getPayrollRecords() async {
    final db = await _db.database;
    final maps = await db.query('payroll', orderBy: 'employeeName ASC');
    return maps.map((m) => _mapToPayroll(m)).toList();
  }

  @override
  Future<void> runPayrollBatch({required String monthYear}) async {
    final db = await _db.database;
    final employees = await db.query('employees');

    final batch = db.batch();
    for (final emp in employees) {
      final empId = emp['id'] as String;
      final name = emp['name'] as String;
      final dept = emp['department'] as String;
      final role = emp['role'] as String;
      final base = (emp['baseSalaryUsd'] as num).toDouble();
      final hourly = (emp['hourlyRateUsd'] as num).toDouble();
      final otHours =
          (empId == 'EMP-101' || empId == 'EMP-107' || empId == 'EMP-111')
          ? 14.0
          : 4.0;
      final otPay = otHours * hourly * 1.5;
      final sprintBonus = 500.0;
      final gross = base + otPay + sprintBonus;

      // Calculate multi-bracket FBR tax and statutory EOBI pension
      final taxResult = TaxEngine.calculateFbrTax(monthlyGrossUsd: gross);

      batch.insert('payroll', {
        'id': 'PAY-$empId',
        'employeeId': empId,
        'employeeName': name,
        'department': dept,
        'role': role,
        'baseSalaryUsd': base,
        'sprintBonusUsd': sprintBonus,
        'overtimeHours': otHours,
        'overtimeRateMultiplier': 1.5,
        'overtimePayUsd': otPay,
        'incomeTaxUsd': taxResult.monthlyTaxUsd,
        'providentFundUsd': taxResult.providentFundMonthlyUsd,
        'eobiContributionUsd': taxResult.eobiEmployeeMonthlyUsd,
        'effectiveTaxRate': taxResult.effectiveTaxRate,
        'taxJurisdiction': 'FBR_PKR',
        'netPayableUsd': taxResult.netMonthlyPayableUsd,
        'status': 'Pending',
        'disbursedAt': null,
        'monthYear': monthYear,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<PayrollRecord> disbursePayroll({required String recordId}) async {
    final db = await _db.database;
    final now = DateTime.now();
    await db.update(
      'payroll',
      {'status': 'Disbursed', 'disbursedAt': now.toIso8601String()},
      where: 'id = ?',
      whereArgs: [recordId],
    );

    final maps = await db.query(
      'payroll',
      where: 'id = ?',
      whereArgs: [recordId],
    );
    return _mapToPayroll(maps.first);
  }

  @override
  Future<PayrollRecord> recalculatePayrollRecord(PayrollRecord record) async {
    final gross =
        record.baseSalaryUsd + record.overtimePayUsd + record.sprintBonusUsd;

    final taxResult = record.taxJurisdiction == 'FEDERAL_USD'
        ? TaxEngine.calculateUsdFederalTax(monthlyGrossUsd: gross)
        : TaxEngine.calculateFbrTax(monthlyGrossUsd: gross);

    final updated = record.copyWith(
      incomeTaxUsd: taxResult.monthlyTaxUsd,
      providentFundUsd: taxResult.providentFundMonthlyUsd,
      eobiContributionUsd: taxResult.eobiEmployeeMonthlyUsd,
      effectiveTaxRate: taxResult.effectiveTaxRate,
      netPayableUsd: taxResult.netMonthlyPayableUsd,
    );

    final db = await _db.database;
    await db.update(
      'payroll',
      {
        'baseSalaryUsd': updated.baseSalaryUsd,
        'sprintBonusUsd': updated.sprintBonusUsd,
        'overtimeHours': updated.overtimeHours,
        'overtimePayUsd': updated.overtimePayUsd,
        'incomeTaxUsd': updated.incomeTaxUsd,
        'providentFundUsd': updated.providentFundUsd,
        'eobiContributionUsd': updated.eobiContributionUsd,
        'effectiveTaxRate': updated.effectiveTaxRate,
        'taxJurisdiction': updated.taxJurisdiction,
        'netPayableUsd': updated.netPayableUsd,
      },
      where: 'id = ?',
      whereArgs: [updated.id],
    );

    return updated;
  }

  PayrollRecord _mapToPayroll(Map<String, dynamic> map) {
    return PayrollRecord(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      employeeName: map['employeeName'] as String,
      department: map['department'] as String,
      role: map['role'] as String,
      baseSalaryUsd: (map['baseSalaryUsd'] as num).toDouble(),
      sprintBonusUsd: (map['sprintBonusUsd'] as num).toDouble(),
      overtimeHours: (map['overtimeHours'] as num).toDouble(),
      overtimeRateMultiplier: (map['overtimeRateMultiplier'] as num).toDouble(),
      overtimePayUsd: (map['overtimePayUsd'] as num).toDouble(),
      incomeTaxUsd: (map['incomeTaxUsd'] as num).toDouble(),
      providentFundUsd: (map['providentFundUsd'] as num).toDouble(),
      eobiContributionUsd:
          (map['eobiContributionUsd'] as num?)?.toDouble() ?? 1.33,
      effectiveTaxRate: (map['effectiveTaxRate'] as num?)?.toDouble() ?? 15.0,
      taxJurisdiction: (map['taxJurisdiction'] as String?) ?? 'FBR_PKR',
      netPayableUsd: (map['netPayableUsd'] as num).toDouble(),
      status: map['status'] as String,
      disbursedAt: map['disbursedAt'] != null
          ? DateTime.parse(map['disbursedAt'] as String)
          : null,
      monthYear: map['monthYear'] as String,
    );
  }
}
