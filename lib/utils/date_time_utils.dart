import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class DateTimeUtils {
  static const zone = 'Asia/Jakarta';
  static DateTime local(DateTime utc, [String timezone = zone]) =>
      tz.TZDateTime.from(utc, tz.getLocation(timezone));
  static String date(DateTime utc, [String timezone = zone]) =>
      DateFormat('d MMM yyyy', 'id_ID').format(local(utc, timezone));
  static String time(DateTime utc, [String timezone = zone]) =>
      // HH:mm has no localized month/day names, so it does not need optional
      // intl locale data to be initialized by a caller.
      DateFormat('HH:mm').format(local(utc, timezone));
  static String full(DateTime utc, [String timezone = zone]) =>
      '${date(utc, timezone)} · ${time(utc, timezone)}';
  static DateTime fromWallTime(
    DateTime date,
    int hour,
    int minute, [
    String timezone = zone,
  ]) => tz.TZDateTime(
    tz.getLocation(timezone),
    date.year,
    date.month,
    date.day,
    hour,
    minute,
  ).toUtc();
}
