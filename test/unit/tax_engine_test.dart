import 'package:flutter_test/flutter_test.dart';
import 'package:octet_pulse_app/core/constants/app_constants.dart';
import 'package:octet_pulse_app/domain/services/tax_engine.dart';

void main() {
  group('TaxEngine Unit Tests', () {
    const exchangeRate = AppConstants.usdToPkrRate; // 278.50

    group('Statutory EOBI Pension Calculations', () {
      test(
        'calculates exact statutory 1% employee and 5% employer contributions',
        () {
          final eobi = TaxEngine.calculateEobi(exchangeRate: exchangeRate);

          expect(eobi['employeePkr'], 370.0); // 1% of 37,000
          expect(eobi['employerPkr'], 1850.0); // 5% of 37,000
          expect(eobi['totalPkr'], 2220.0);

          expect(eobi['employeeUsd']!, closeTo(370.0 / exchangeRate, 0.01));
          expect(eobi['employerUsd']!, closeTo(1850.0 / exchangeRate, 0.01));
          expect(eobi['totalUsd']!, closeTo(2220.0 / exchangeRate, 0.01));
        },
      );
    });

    group('Pakistan FBR 2026-2027 Progressive Tax Slabs', () {
      test('Slab 1: Tax-exempt when annual salary is <= PKR 600,000', () {
        // PKR 50,000/mo -> PKR 600,000/yr
        final monthlyUsd = (50000.0 / exchangeRate);
        final result = TaxEngine.calculateFbrTax(
          monthlyGrossUsd: monthlyUsd,
          exchangeRate: exchangeRate,
        );

        expect(result.annualTaxUsd, 0.0);
        expect(result.monthlyTaxUsd, 0.0);
        expect(result.effectiveTaxRate, 0.0);
        expect(result.marginalTaxRate, 0.0);
        expect(result.slabDescription, contains('Slab 1: Tax-Exempt'));
      });

      test('Slab 2: 5% of excess over PKR 600,000 (PKR 600K - 1.2M)', () {
        // PKR 80,000/mo -> PKR 960,000/yr. Excess = PKR 360,000. Tax = 5% of 360K = PKR 18,000/yr
        final monthlyUsd = (80000.0 / exchangeRate);
        final result = TaxEngine.calculateFbrTax(
          monthlyGrossUsd: monthlyUsd,
          exchangeRate: exchangeRate,
        );

        final expectedAnnualPkr = 18000.0;
        final expectedAnnualUsd = expectedAnnualPkr / exchangeRate;

        expect(result.annualTaxUsd, closeTo(expectedAnnualUsd, 0.01));
        expect(result.monthlyTaxUsd, closeTo(expectedAnnualUsd / 12.0, 0.01));
        expect(result.marginalTaxRate, 5.0);
        expect(result.slabDescription, contains('Slab 2'));
      });

      test(
        'Slab 3: PKR 30,000 + 15% of excess over PKR 1.2M (PKR 1.2M - 2.2M)',
        () {
          // PKR 150,000/mo -> PKR 1,800,000/yr. Excess over 1.2M = 600K. Tax = 30K + 15%(600K) = 30K + 90K = PKR 120,000/yr
          final monthlyUsd = (150000.0 / exchangeRate);
          final result = TaxEngine.calculateFbrTax(
            monthlyGrossUsd: monthlyUsd,
            exchangeRate: exchangeRate,
          );

          final expectedAnnualPkr = 120000.0;
          final expectedAnnualUsd = expectedAnnualPkr / exchangeRate;

          expect(result.annualTaxUsd, closeTo(expectedAnnualUsd, 0.01));
          expect(result.monthlyTaxUsd, closeTo(expectedAnnualUsd / 12.0, 0.01));
          expect(result.marginalTaxRate, 15.0);
          expect(result.slabDescription, contains('Slab 3'));
        },
      );

      test(
        'Slab 4: PKR 180,000 + 25% of excess over PKR 2.2M (PKR 2.2M - 3.2M)',
        () {
          // PKR 250,000/mo -> PKR 3,000,000/yr. Excess over 2.2M = 800K. Tax = 180K + 25%(800K) = 180K + 200K = PKR 380,000/yr
          final monthlyUsd = (250000.0 / exchangeRate);
          final result = TaxEngine.calculateFbrTax(
            monthlyGrossUsd: monthlyUsd,
            exchangeRate: exchangeRate,
          );

          final expectedAnnualPkr = 380000.0;
          final expectedAnnualUsd = expectedAnnualPkr / exchangeRate;

          expect(result.annualTaxUsd, closeTo(expectedAnnualUsd, 0.01));
          expect(result.monthlyTaxUsd, closeTo(expectedAnnualUsd / 12.0, 0.01));
          expect(result.marginalTaxRate, 25.0);
          expect(result.slabDescription, contains('Slab 4'));
        },
      );

      test(
        'Slab 5: PKR 430,000 + 30% of excess over PKR 3.2M (PKR 3.2M - 4.1M)',
        () {
          // PKR 300,000/mo -> PKR 3,600,000/yr. Excess over 3.2M = 400K. Tax = 430K + 30%(400K) = 430K + 120K = PKR 550,000/yr
          final monthlyUsd = (300000.0 / exchangeRate);
          final result = TaxEngine.calculateFbrTax(
            monthlyGrossUsd: monthlyUsd,
            exchangeRate: exchangeRate,
          );

          final expectedAnnualPkr = 550000.0;
          final expectedAnnualUsd = expectedAnnualPkr / exchangeRate;

          expect(result.annualTaxUsd, closeTo(expectedAnnualUsd, 0.01));
          expect(result.monthlyTaxUsd, closeTo(expectedAnnualUsd / 12.0, 0.01));
          expect(result.marginalTaxRate, 30.0);
          expect(result.slabDescription, contains('Slab 5'));
        },
      );

      test(
        'Slab 6: PKR 700,000 + 35% of excess over PKR 4.1M (> PKR 4.1M)',
        () {
          // PKR 500,000/mo -> PKR 6,000,000/yr. Excess over 4.1M = 1.9M. Tax = 700K + 35%(1.9M) = 700K + 665K = PKR 1,365,000/yr
          final monthlyUsd = (500000.0 / exchangeRate);
          final result = TaxEngine.calculateFbrTax(
            monthlyGrossUsd: monthlyUsd,
            exchangeRate: exchangeRate,
          );

          final expectedAnnualPkr = 1365000.0;
          final expectedAnnualUsd = expectedAnnualPkr / exchangeRate;

          expect(result.annualTaxUsd, closeTo(expectedAnnualUsd, 0.01));
          expect(result.monthlyTaxUsd, closeTo(expectedAnnualUsd / 12.0, 0.01));
          expect(result.marginalTaxRate, 35.0);
          expect(result.slabDescription, contains('Slab 6'));
        },
      );
    });

    group('US Federal Progressive Tax Brackets', () {
      test('Tier 1: 10% on earnings up to \$11,600/yr', () {
        final result = TaxEngine.calculateUsdFederalTax(
          monthlyGrossUsd: 800.0,
        ); // \$9,600/yr
        expect(result.annualTaxUsd, closeTo(960.0, 0.01));
        expect(result.monthlyTaxUsd, closeTo(80.0, 0.01));
        expect(result.marginalTaxRate, 10.0);
        expect(result.slabDescription, contains('Tier 1'));
      });

      test(
        'Tier 2: \$1,160 + 12% on excess over \$11,600 (\$11,600 - \$47,150)',
        () {
          final result = TaxEngine.calculateUsdFederalTax(
            monthlyGrossUsd: 2500.0,
          ); // \$30,000/yr
          // Excess = 30,000 - 11,600 = 18,400. Tax = 1,160 + 12%(18,400) = 1,160 + 2,208 = \$3,368/yr
          expect(result.annualTaxUsd, closeTo(3368.0, 0.01));
          expect(result.monthlyTaxUsd, closeTo(3368.0 / 12.0, 0.01));
          expect(result.marginalTaxRate, 12.0);
          expect(result.slabDescription, contains('Tier 2'));
        },
      );

      test(
        'Tier 3: \$5,426 + 22% on excess over \$47,150 (\$47,150 - \$100,525)',
        () {
          final result = TaxEngine.calculateUsdFederalTax(
            monthlyGrossUsd: 5000.0,
          ); // \$60,000/yr
          // Excess = 60,000 - 47,150 = 12,850. Tax = 5,426 + 22%(12,850) = 5,426 + 2,827 = \$8,253/yr
          expect(result.annualTaxUsd, closeTo(8253.0, 0.01));
          expect(result.monthlyTaxUsd, closeTo(8253.0 / 12.0, 0.01));
          expect(result.marginalTaxRate, 22.0);
          expect(result.slabDescription, contains('Tier 3'));
        },
      );

      test('Tier 4: \$17,168.50 + 24% on excess over \$100,525 (\$100,525 - \$191,950)', () {
        final result = TaxEngine.calculateUsdFederalTax(
          monthlyGrossUsd: 10000.0,
        ); // \$120,000/yr
        // Excess = 120,000 - 100,525 = 19,475. Tax = 17,168.50 + 24%(19,475) = 17,168.50 + 4,674 = \$21,842.50/yr
        expect(result.annualTaxUsd, closeTo(21842.50, 0.01));
        expect(result.monthlyTaxUsd, closeTo(21842.50 / 12.0, 0.01));
        expect(result.marginalTaxRate, 24.0);
        expect(result.slabDescription, contains('Tier 4'));
      });

      test(
        'Tier 5: \$39,110.50 + 32% on excess over \$191,950 (> \$191,950)',
        () {
          final result = TaxEngine.calculateUsdFederalTax(
            monthlyGrossUsd: 20000.0,
          ); // \$240,000/yr
          // Excess = 240,000 - 191,950 = 48,050. Tax = 39,110.50 + 32%(48,050) = 39,110.50 + 15,376 = \$54,486.50/yr
          expect(result.annualTaxUsd, closeTo(54486.50, 0.01));
          expect(result.monthlyTaxUsd, closeTo(54486.50 / 12.0, 0.01));
          expect(result.marginalTaxRate, 32.0);
          expect(result.slabDescription, contains('Tier 5'));
        },
      );
    });
  });
}
