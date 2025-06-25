import 'package:timeago/timeago.dart' as timeago;

/// Custom timeago messages for seconds/minutes/hours ago formatting.
class SecondsAgoMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => '';

  @override
  String suffixAgo() => 'ago';

  @override
  String suffixFromNow() => 'from now';

  @override
  String lessThanOneMinute(int seconds) => '$seconds seconds';

  @override
  String aboutAMinute(int minutes) => '1 minute';

  @override
  String minutes(int minutes) => '$minutes minutes';

  @override
  String aboutAnHour(int minutes) => '1 hour';

  @override
  String hours(int hours) => '$hours hours';

  @override
  String aDay(int hours) => '1 day';

  @override
  String days(int days) => '$days days';

  @override
  String aboutAMonth(int days) => '1 month';

  @override
  String months(int months) => '$months months';

  @override
  String aboutAYear(int year) => '1 year';

  @override
  String years(int years) => '$years years';

  @override
  String wordSeparator() => ' ';
}

/// Registers the custom timeago locale for seconds/minutes/hours.
void registerTimeagoLocale() {
  timeago.setLocaleMessages('en_seconds', SecondsAgoMessages());
}

/// Formats a timestamp using the custom timeago locale.
String formatTimestamp(DateTime dt) {
  return timeago.format(dt, locale: 'en_seconds', allowFromNow: true);
}
