import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/domain/entities/payroll_record.dart';
import 'package:octet_pulse_app/presentation/payroll/bloc/payroll_bloc.dart';
import 'package:octet_pulse_app/presentation/payroll/bloc/payroll_event.dart';
import 'package:octet_pulse_app/presentation/payroll/bloc/payroll_state.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('PayrollBloc Unit Tests', () {
    late FakePayrollRepository repository;

    final sampleRecord = const PayrollRecord(
      id: 'PAY-EMP-101',
      employeeId: 'EMP-101',
      employeeName: 'Safeer Hussain',
      department: 'Mobile Engineering',
      role: 'Principal Architect',
      baseSalaryUsd: 9800.0,
      sprintBonusUsd: 500.0,
      overtimeHours: 10.0,
      overtimeRateMultiplier: 1.5,
      overtimePayUsd: 918.75,
      incomeTaxUsd: 1682.81,
      providentFundUsd: 490.0,
      netPayableUsd: 9045.94,
      status: 'Pending',
      monthYear: 'November 2026',
    );

    setUp(() {
      repository = FakePayrollRepository();
      repository.records = [sampleRecord];
    });

    test('initial state has empty records and default USD currency', () {
      final bloc = PayrollBloc(repository);
      expect(bloc.state.status, PayrollStatusState.initial);
      expect(bloc.state.isUsd, true);
      bloc.close();
    });

    blocTest<PayrollBloc, PayrollState>(
      'loads records and calculates total liability metrics correctly',
      build: () => PayrollBloc(repository),
      act: (bloc) => bloc.add(const LoadPayrollData()),
      verify: (bloc) {
        expect(bloc.state.status, PayrollStatusState.loaded);
        expect(bloc.state.records.length, 1);
        expect(bloc.state.totalNetPayableUsd, 9045.94);
        expect(bloc.state.pendingCount, 1);
        expect(bloc.state.disbursedCount, 0);
      },
    );

    blocTest<PayrollBloc, PayrollState>(
      'disburses payroll and updates record status to Disbursed',
      build: () => PayrollBloc(repository),
      seed: () => PayrollState(records: [sampleRecord]),
      act: (bloc) =>
          bloc.add(const DisbursePayrollEvent(recordId: 'PAY-EMP-101')),
      verify: (bloc) {
        expect(bloc.state.records.first.status, 'Disbursed');
        expect(bloc.state.disbursedCount, 1);
        expect(bloc.state.pendingCount, 0);
      },
    );

    blocTest<PayrollBloc, PayrollState>(
      'toggles currency between USD and PKR',
      build: () => PayrollBloc(repository),
      act: (bloc) => bloc.add(const ToggleCurrencyEvent()),
      verify: (bloc) {
        expect(bloc.state.isUsd, false);
      },
    );
  });
}
