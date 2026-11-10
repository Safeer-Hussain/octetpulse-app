import '../entities/payroll_record.dart';

abstract class PayrollRepository {
  Future<List<PayrollRecord>> getPayrollRecords();
  Future<void> runPayrollBatch({required String monthYear});
  Future<PayrollRecord> disbursePayroll({required String recordId});
  Future<PayrollRecord> recalculatePayrollRecord(PayrollRecord record);
}
