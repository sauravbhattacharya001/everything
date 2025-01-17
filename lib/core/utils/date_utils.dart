import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(String isoDate) {
    final dateTime = DateTime.parse(isoDate);
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  static String getCurrentDateTime() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }
}
