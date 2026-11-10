import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class AppFormatters {
  static final NumberFormat _currencyUsd = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final NumberFormat _currencyPkr = NumberFormat.currency(symbol: 'PKR ', decimalDigits: 0);
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, hh:mm a');

  static String formatCurrency(double amountInUsd, {bool isUsd = true}) {
    if (isUsd) {
      return _currencyUsd.format(amountInUsd);
    } else {
      final inPkr = amountInUsd * AppConstants.usdToPkrRate;
      return _currencyPkr.format(inPkr);
    }
  }

  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);

  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);

  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);

  static String formatDurationHoursMins(Duration duration) {
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m';
  }

  static String formatVoipDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}
