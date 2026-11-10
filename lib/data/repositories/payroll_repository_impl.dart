import 'package:sqflite/sqflite.dart';

import '../../domain/entities/payroll_record.dart';
import '../../domain/repositories/payroll_repository.dart';
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
      final tax = gross * 0.15;
      final pf = base * 0.05;
      final net = gross - tax - pf;

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
        'incomeTaxUsd': tax,
        'providentFundUsd': pf,
        'netPayableUsd': net,
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
    final tax = gross * 0.15;
    final pf = record.baseSalaryUsd * 0.05;
    final net = gross - tax - pf;

    final updated = record.copyWith(
      incomeTaxUsd: tax,
      providentFundUsd: pf,
      netPayableUsd: net,
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
      netPayableUsd: (map['netPayableUsd'] as num).toDouble(),
      status: map['status'] as String,
      disbursedAt: map['disbursedAt'] != null
          ? DateTime.parse(map['disbursedAt'] as String)
          : null,
      monthYear: map['monthYear'] as String,
    );
  }
}
