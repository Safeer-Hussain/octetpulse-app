import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_formatters.dart';
import '../../../domain/entities/payroll_record.dart';
import '../bloc/payroll_bloc.dart';
import '../bloc/payroll_event.dart';

class PayslipBreakdownSheet extends StatelessWidget {
  final PayrollRecord record;
  final bool isUsd;

  const PayslipBreakdownSheet({
    super.key,
    required this.record,
    required this.isUsd,
  });

  void _copyToClipboard(BuildContext context) {
    final currencySymbol = isUsd ? '\$' : 'PKR ';
    final multiplier = isUsd ? 1.0 : 278.50;

    final summary =
        '''
OCTETPULSE ENTERPRISE PAYSLIP BREAKDOWN
Employee: ${record.employeeName} (${record.employeeId})
Department: ${record.department} - ${record.role}
Month: ${record.monthYear}
Status: ${record.status}
Jurisdiction: ${record.taxJurisdiction}
Effective Tax Rate: ${record.effectiveTaxRate.toStringAsFixed(1)}%
----------------------------------------
Base Salary: $currencySymbol${(record.baseSalaryUsd * multiplier).toStringAsFixed(2)}
Sprint Velocity Bonus: $currencySymbol${(record.sprintBonusUsd * multiplier).toStringAsFixed(2)}
Overtime Pay (${record.overtimeHours.toStringAsFixed(1)} hrs @ 1.5x): $currencySymbol${(record.overtimePayUsd * multiplier).toStringAsFixed(2)}
----------------------------------------
Gross Earnings: $currencySymbol${(record.grossEarningsUsd * multiplier).toStringAsFixed(2)}
Income Tax Withheld (${record.effectiveTaxRate.toStringAsFixed(1)}%): -$currencySymbol${(record.incomeTaxUsd * multiplier).toStringAsFixed(2)}
Provident Fund (5%): -$currencySymbol${(record.providentFundUsd * multiplier).toStringAsFixed(2)}
EOBI Pension Contribution (1% statutory): -$currencySymbol${(record.eobiContributionUsd * multiplier).toStringAsFixed(2)}
----------------------------------------
Total Deductions: -$currencySymbol${(record.totalDeductionsUsd * multiplier).toStringAsFixed(2)}
NET DISBURSED AMOUNT: $currencySymbol${(record.netPayableUsd * multiplier).toStringAsFixed(2)}
Generated via OctetPulse Encrypted Payroll Ledger
''';

    Clipboard.setData(ClipboardData(text: summary));
    AppFeedback.showSuccess(
      context,
      'Formatted payslip summary copied to clipboard.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDisbursed = record.status == 'Disbursed';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.employeeName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${record.employeeId} • ${record.department} • ${record.role}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISBURSEMENT STATUS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isDisbursed
                                ? colorScheme.secondaryContainer
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            record.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDisbursed
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TAX REGIME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${record.taxJurisdiction} • ${record.effectiveTaxRate.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDeductionsChart(context),
              const SizedBox(height: 16),
              _buildRow(
                context,
                'Base Monthly Salary',
                AppFormatters.formatCurrency(
                  record.baseSalaryUsd,
                  isUsd: isUsd,
                ),
              ),
              _buildRow(
                context,
                'Sprint Velocity Bonus',
                AppFormatters.formatCurrency(
                  record.sprintBonusUsd,
                  isUsd: isUsd,
                ),
              ),
              _buildRow(
                context,
                'Overtime Pay (${record.overtimeHours.toStringAsFixed(1)} hrs @ 1.5x)',
                AppFormatters.formatCurrency(
                  record.overtimePayUsd,
                  isUsd: isUsd,
                ),
              ),
              Divider(color: colorScheme.outlineVariant, height: 20),
              _buildRow(
                context,
                'Gross Monthly Earnings',
                AppFormatters.formatCurrency(
                  record.grossEarningsUsd,
                  isUsd: isUsd,
                ),
                isBold: true,
              ),
              Divider(color: colorScheme.outlineVariant, height: 20),
              _buildRow(
                context,
                'Income Tax Withholding (${record.effectiveTaxRate.toStringAsFixed(1)}%)',
                '-${AppFormatters.formatCurrency(record.incomeTaxUsd, isUsd: isUsd)}',
                isNegative: true,
              ),
              _buildRow(
                context,
                'Provident Fund Deduction (5%)',
                '-${AppFormatters.formatCurrency(record.providentFundUsd, isUsd: isUsd)}',
                isNegative: true,
              ),
              _buildRow(
                context,
                'EOBI Pension Contribution (1% statutory)',
                '-${AppFormatters.formatCurrency(record.eobiContributionUsd, isUsd: isUsd)}',
                isNegative: true,
              ),
              Divider(color: colorScheme.outlineVariant, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Net Disbursable Amount',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(
                      record.netPayableUsd,
                      isUsd: isUsd,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context),
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Export Summary'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (!isDisbursed)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.read<PayrollBloc>().add(
                            DisbursePayrollEvent(recordId: record.id),
                          );
                          Navigator.of(context).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Disburse Now'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeductionsChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final netPay = record.netPayableUsd;
    final tax = record.incomeTaxUsd;
    final pf = record.providentFundUsd;
    final eobi = record.eobiContributionUsd;
    final total = netPay + tax + pf + eobi;

    if (total <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DISBURSEMENT RATIO',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '${((netPay / total) * 100).toStringAsFixed(1)}% Take-Home',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      sections: [
                        PieChartSectionData(
                          value: netPay,
                          title: '',
                          color: colorScheme.secondary,
                          radius: 20,
                        ),
                        PieChartSectionData(
                          value: tax,
                          title: '',
                          color: colorScheme.error,
                          radius: 18,
                        ),
                        PieChartSectionData(
                          value: pf,
                          title: '',
                          color: colorScheme.tertiary,
                          radius: 16,
                        ),
                        PieChartSectionData(
                          value: eobi,
                          title: '',
                          color: colorScheme.primary,
                          radius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        context,
                        'Net Pay',
                        netPay,
                        colorScheme.secondary,
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                        context,
                        'Income Tax',
                        tax,
                        colorScheme.error,
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                        context,
                        'Provident Fund',
                        pf,
                        colorScheme.tertiary,
                      ),
                      const SizedBox(height: 4),
                      _buildLegendItem(
                        context,
                        'EOBI Pension',
                        eobi,
                        colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    double amountUsd,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          AppFormatters.formatCurrency(amountUsd, isUsd: isUsd),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String amount, {
    bool isNegative = false,
    bool isBold = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: (isNegative || isBold)
                  ? FontWeight.bold
                  : FontWeight.w600,
              color: isNegative
                  ? colorScheme.error
                  : isBold
                  ? colorScheme.onSurface
                  : colorScheme.onSurface,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
