import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/theme/app_theme.dart';
import 'package:octet_pulse_app/domain/entities/payroll_record.dart';
import 'package:octet_pulse_app/presentation/payroll/bloc/payroll_bloc.dart';
import 'package:octet_pulse_app/presentation/payroll/views/payslip_breakdown_sheet.dart';

import '../fakes/fake_repositories.dart';

void main() {
  const sampleRecord = PayrollRecord(
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
    eobiContributionUsd: 1.33,
    effectiveTaxRate: 15.0,
    taxJurisdiction: 'FBR_PKR',
    netPayableUsd: 8544.61,
    status: 'Pending',
    monthYear: 'November 2026',
  );

  Widget createSubject({required bool isDark, required bool isUsd}) {
    final fakeRepo = FakePayrollRepository();
    fakeRepo.records = [sampleRecord];

    return BlocProvider<PayrollBloc>(
      create: (_) => PayrollBloc(fakeRepo),
      child: MaterialApp(
        theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
        home: const Scaffold(
          body: PayslipBreakdownSheet(record: sampleRecord, isUsd: true),
        ),
      ),
    );
  }

  testWidgets(
    'PayslipBreakdownSheet renders tax jurisdiction, EOBI, and take-home ratio',
    (WidgetTester tester) async {
      await tester.pumpWidget(createSubject(isDark: true, isUsd: true));
      await tester.pumpAndSettle();

      expect(find.text('Safeer Hussain'), findsOneWidget);
      expect(find.text('FBR_PKR • 15.0%'), findsOneWidget);
      expect(
        find.text('EOBI Pension Contribution (1% statutory)'),
        findsOneWidget,
      );
      expect(find.text('Gross Monthly Earnings'), findsOneWidget);
      expect(find.text('Net Disbursable Amount'), findsOneWidget);
      expect(find.text('DISBURSEMENT RATIO'), findsOneWidget);
      expect(find.text('Export Summary'), findsOneWidget);
      expect(find.text('Disburse Now'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PayslipBreakdownSheet renders with zero overflow on 800x360 landscape viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createSubject(isDark: false, isUsd: true));
      await tester.pumpAndSettle();

      expect(find.byType(PayslipBreakdownSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
