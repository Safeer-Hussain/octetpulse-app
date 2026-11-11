import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

enum TaxJurisdiction { fbrPakistan, federalUsd }

class TaxCalculationResult extends Equatable {
  final double monthlyGrossUsd;
  final double annualGrossUsd;
  final double monthlyTaxUsd;
  final double annualTaxUsd;
  final double effectiveTaxRate; // e.g. 15.2%
  final double marginalTaxRate; // e.g. 25.0%
  final String slabDescription;
  final double eobiEmployeeMonthlyUsd;
  final double eobiEmployerMonthlyUsd;
  final double eobiTotalMonthlyUsd;
  final double providentFundMonthlyUsd;
  final double totalDeductionsMonthlyUsd;
  final double netMonthlyPayableUsd;
  final TaxJurisdiction jurisdiction;

  const TaxCalculationResult({
    required this.monthlyGrossUsd,
    required this.annualGrossUsd,
    required this.monthlyTaxUsd,
    required this.annualTaxUsd,
    required this.effectiveTaxRate,
    required this.marginalTaxRate,
    required this.slabDescription,
    required this.eobiEmployeeMonthlyUsd,
    required this.eobiEmployerMonthlyUsd,
    required this.eobiTotalMonthlyUsd,
    required this.providentFundMonthlyUsd,
    required this.totalDeductionsMonthlyUsd,
    required this.netMonthlyPayableUsd,
    required this.jurisdiction,
  });

  @override
  List<Object?> get props => [
    monthlyGrossUsd,
    annualGrossUsd,
    monthlyTaxUsd,
    annualTaxUsd,
    effectiveTaxRate,
    marginalTaxRate,
    slabDescription,
    eobiEmployeeMonthlyUsd,
    eobiEmployerMonthlyUsd,
    eobiTotalMonthlyUsd,
    providentFundMonthlyUsd,
    totalDeductionsMonthlyUsd,
    netMonthlyPayableUsd,
    jurisdiction,
  ];
}

class TaxEngine {
  // Statutory Pakistan EOBI constants
  static const double eobiMinimumWagePkr = 37000.0;
  static const double eobiEmployeeRate = 0.01; // 1%
  static const double eobiEmployerRate = 0.05; // 5%

  // Standard Provident Fund deduction
  static const double standardPfRate = 0.05; // 5%

  /// Calculates EOBI contribution in USD
  static Map<String, double> calculateEobi({
    double exchangeRate = AppConstants.usdToPkrRate,
  }) {
    final employeePkr = eobiMinimumWagePkr * eobiEmployeeRate; // PKR 370
    final employerPkr = eobiMinimumWagePkr * eobiEmployerRate; // PKR 1850
    final totalPkr = employeePkr + employerPkr; // PKR 2220

    return {
      'employeeUsd': employeePkr / exchangeRate,
      'employerUsd': employerPkr / exchangeRate,
      'totalUsd': totalPkr / exchangeRate,
      'employeePkr': employeePkr,
      'employerPkr': employerPkr,
      'totalPkr': totalPkr,
    };
  }

  /// Calculates Pakistan FBR (Tax Year 2026-2027) progressive tax for salaried individuals
  static TaxCalculationResult calculateFbrTax({
    required double monthlyGrossUsd,
    double pfRate = standardPfRate,
    double exchangeRate = AppConstants.usdToPkrRate,
  }) {
    final annualGrossUsd = monthlyGrossUsd * 12.0;
    final annualGrossPkr = annualGrossUsd * exchangeRate;

    double annualTaxPkr = 0.0;
    double marginalRate = 0.0;
    String slab = 'Slab 1: Tax-Exempt (Up to PKR 600K/yr)';

    if (annualGrossPkr <= 600000.0) {
      // Slab 1: Up to PKR 600,000 -> 0%
      annualTaxPkr = 0.0;
      marginalRate = 0.0;
      slab = 'Slab 1: Tax-Exempt (Up to PKR 600,000/yr)';
    } else if (annualGrossPkr <= 1200000.0) {
      // Slab 2: PKR 600,001 - 1,200,000 -> 5% of excess
      annualTaxPkr = (annualGrossPkr - 600000.0) * 0.05;
      marginalRate = 0.05;
      slab = 'Slab 2: 5% on excess over PKR 600,000';
    } else if (annualGrossPkr <= 2200000.0) {
      // Slab 3: PKR 1,200,001 - 2,200,000 -> PKR 30,000 + 15% of excess
      annualTaxPkr = 30000.0 + ((annualGrossPkr - 1200000.0) * 0.15);
      marginalRate = 0.15;
      slab = 'Slab 3: PKR 30K + 15% on excess over PKR 1.2M';
    } else if (annualGrossPkr <= 3200000.0) {
      // Slab 4: PKR 2,200,001 - 3,200,000 -> PKR 180,000 + 25% of excess
      annualTaxPkr = 180000.0 + ((annualGrossPkr - 2200000.0) * 0.25);
      marginalRate = 0.25;
      slab = 'Slab 4: PKR 180K + 25% on excess over PKR 2.2M';
    } else if (annualGrossPkr <= 4100000.0) {
      // Slab 5: PKR 3,200,001 - 4,100,000 -> PKR 430,000 + 30% of excess
      annualTaxPkr = 430000.0 + ((annualGrossPkr - 3200000.0) * 0.30);
      marginalRate = 0.30;
      slab = 'Slab 5: PKR 430K + 30% on excess over PKR 3.2M';
    } else {
      // Slab 6: Exceeding PKR 4,100,000 -> PKR 700,000 + 35% of excess
      annualTaxPkr = 700000.0 + ((annualGrossPkr - 4100000.0) * 0.35);
      marginalRate = 0.35;
      slab = 'Slab 6: PKR 700K + 35% on excess over PKR 4.1M';
    }

    final monthlyTaxPkr = annualTaxPkr / 12.0;
    final monthlyTaxUsd = monthlyTaxPkr / exchangeRate;
    final annualTaxUsd = annualTaxPkr / exchangeRate;

    final eobi = calculateEobi(exchangeRate: exchangeRate);
    final eobiEmployeeUsd = eobi['employeeUsd']!;
    final eobiEmployerUsd = eobi['employerUsd']!;
    final eobiTotalUsd = eobi['totalUsd']!;

    final pfMonthlyUsd = monthlyGrossUsd * pfRate;
    final totalDeductionsUsd = monthlyTaxUsd + pfMonthlyUsd + eobiEmployeeUsd;
    final netPayableUsd = monthlyGrossUsd - totalDeductionsUsd;

    final effectiveRate = monthlyGrossUsd > 0
        ? (monthlyTaxUsd / monthlyGrossUsd) * 100.0
        : 0.0;

    return TaxCalculationResult(
      monthlyGrossUsd: monthlyGrossUsd,
      annualGrossUsd: annualGrossUsd,
      monthlyTaxUsd: monthlyTaxUsd,
      annualTaxUsd: annualTaxUsd,
      effectiveTaxRate: effectiveRate,
      marginalTaxRate: marginalRate * 100.0,
      slabDescription: slab,
      eobiEmployeeMonthlyUsd: eobiEmployeeUsd,
      eobiEmployerMonthlyUsd: eobiEmployerUsd,
      eobiTotalMonthlyUsd: eobiTotalUsd,
      providentFundMonthlyUsd: pfMonthlyUsd,
      totalDeductionsMonthlyUsd: totalDeductionsUsd,
      netMonthlyPayableUsd: netPayableUsd,
      jurisdiction: TaxJurisdiction.fbrPakistan,
    );
  }

  /// Calculates US Federal multi-bracket progressive withholding tax
  static TaxCalculationResult calculateUsdFederalTax({
    required double monthlyGrossUsd,
    double pfRate = standardPfRate,
    double exchangeRate = AppConstants.usdToPkrRate,
  }) {
    final annualGrossUsd = monthlyGrossUsd * 12.0;

    double annualTaxUsd = 0.0;
    double marginalRate = 0.10;
    String slab = 'Tier 1: 10% (Up to \$11,600/yr)';

    if (annualGrossUsd <= 11600.0) {
      annualTaxUsd = annualGrossUsd * 0.10;
      marginalRate = 0.10;
      slab = 'Tier 1: 10% (Up to \$11,600/yr)';
    } else if (annualGrossUsd <= 47150.0) {
      annualTaxUsd = 1160.0 + ((annualGrossUsd - 11600.0) * 0.12);
      marginalRate = 0.12;
      slab = 'Tier 2: \$1,160 + 12% on excess > \$11,600';
    } else if (annualGrossUsd <= 100525.0) {
      annualTaxUsd = 5426.0 + ((annualGrossUsd - 47150.0) * 0.22);
      marginalRate = 0.22;
      slab = 'Tier 3: \$5,426 + 22% on excess > \$47,150';
    } else if (annualGrossUsd <= 191950.0) {
      annualTaxUsd = 17168.50 + ((annualGrossUsd - 100525.0) * 0.24);
      marginalRate = 0.24;
      slab = 'Tier 4: \$17,168.50 + 24% on excess > \$100,525';
    } else {
      annualTaxUsd = 39110.50 + ((annualGrossUsd - 191950.0) * 0.32);
      marginalRate = 0.32;
      slab = 'Tier 5: \$39,110.50 + 32% on excess > \$191,950';
    }

    final monthlyTaxUsd = annualTaxUsd / 12.0;

    final eobi = calculateEobi(exchangeRate: exchangeRate);
    final eobiEmployeeUsd = eobi['employeeUsd']!;
    final eobiEmployerUsd = eobi['employerUsd']!;
    final eobiTotalUsd = eobi['totalUsd']!;

    final pfMonthlyUsd = monthlyGrossUsd * pfRate;
    final totalDeductionsUsd = monthlyTaxUsd + pfMonthlyUsd + eobiEmployeeUsd;
    final netPayableUsd = monthlyGrossUsd - totalDeductionsUsd;

    final effectiveRate = monthlyGrossUsd > 0
        ? (monthlyTaxUsd / monthlyGrossUsd) * 100.0
        : 0.0;

    return TaxCalculationResult(
      monthlyGrossUsd: monthlyGrossUsd,
      annualGrossUsd: annualGrossUsd,
      monthlyTaxUsd: monthlyTaxUsd,
      annualTaxUsd: annualTaxUsd,
      effectiveTaxRate: effectiveRate,
      marginalTaxRate: marginalRate * 100.0,
      slabDescription: slab,
      eobiEmployeeMonthlyUsd: eobiEmployeeUsd,
      eobiEmployerMonthlyUsd: eobiEmployerUsd,
      eobiTotalMonthlyUsd: eobiTotalUsd,
      providentFundMonthlyUsd: pfMonthlyUsd,
      totalDeductionsMonthlyUsd: totalDeductionsUsd,
      netMonthlyPayableUsd: netPayableUsd,
      jurisdiction: TaxJurisdiction.federalUsd,
    );
  }
}
