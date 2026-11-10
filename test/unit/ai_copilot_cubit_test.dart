import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:octet_pulse_app/data/datasources/local/app_database.dart';
import 'package:octet_pulse_app/presentation/ai_copilot/cubit/ai_copilot_cubit.dart';
import 'package:sqflite/sqflite.dart';

class MockAppDatabase extends Mock implements AppDatabase {}

class MockDatabase extends Mock implements Database {}

void main() {
  group('AiCopilotCubit Unit Tests', () {
    late MockAppDatabase mockDb;
    late MockDatabase mockDatabase;

    setUp(() {
      mockDb = MockAppDatabase();
      mockDatabase = MockDatabase();
      when(() => mockDb.database).thenAnswer((_) async => mockDatabase);
    });

    test('initial state has intro message and isStreaming is false', () {
      final cubit = AiCopilotCubit(mockDb);
      expect(cubit.state.messages.length, 1);
      expect(cubit.state.messages.first.role, 'assistant');
      expect(cubit.state.isStreaming, false);
      cubit.close();
    });

    test('clearConversation resets messages and isStreaming is false', () {
      final cubit = AiCopilotCubit(mockDb);
      cubit.clearConversation();
      expect(cubit.state.messages.length, 1);
      expect(cubit.state.isStreaming, false);
      cubit.close();
    });

    test(
      'sendPrompt guarantees isStreaming resets to false in finally block',
      () async {
        when(() => mockDatabase.rawQuery(any())).thenAnswer(
          (_) async => [
            {
              'COUNT(*)': 26,
              'SUM(baseSalaryUsd)': 180000.0,
              'SUM(overtimePayUsd)': 4200.0,
              'SUM(netPayableUsd)': 155000.0,
            },
          ],
        );

        final cubit = AiCopilotCubit(mockDb);
        final future = cubit.sendPrompt(
          'Audit This Month\'s Payroll & Overtime Variance',
        );
        expect(cubit.state.isStreaming, true);

        await future;
        expect(cubit.state.isStreaming, false);
        expect(cubit.state.messages.last.role, 'assistant');
        expect(cubit.state.messages.last.isStreaming, false);
        cubit.close();
      },
    );
  });
}
