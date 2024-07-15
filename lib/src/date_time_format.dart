import 'printers/pretty_printer.dart';

typedef DateTimeFormatter = String Function(DateTime time);

class DateTimeFormat {
  /// Omits the date and time completely.
  static const DateTimeFormatter none = _none;

  /// Prints only the time.
  ///
  /// Example:
  /// * `12:30:40.550`
  static const DateTimeFormatter onlyTime = _onlyTime;

  /// Prints only the time including the difference since [PrettyPrinter.startTime].
  ///
  /// Example:
  /// * `12:30:40.550 (+0:00:00.060700)`
  static const DateTimeFormatter onlyTimeAndSinceStart = _onlyTimeAndSinceStart;

  /// Prints only the date.
  ///
  /// Example:
  /// * `2019-06-04`
  static const DateTimeFormatter onlyDate = _onlyDate;

  /// Prints date and time (combines [onlyDate] and [onlyTime]).
  ///
  /// Example:
  /// * `2019-06-04 12:30:40.550`
  static const DateTimeFormatter dateAndTime = _dateAndTime;

  DateTimeFormat._();

  static String _none(DateTime t) => throw UnimplementedError();

  static String _onlyTime(DateTime t) {
    String threeDigits(int n) {
      if (n >= 100) return '$n';
      if (n >= 10) return '0$n';
      return '00$n';
    }

    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    var now = t;
    var h = twoDigits(now.hour);
    var min = twoDigits(now.minute);
    var sec = twoDigits(now.second);
    var ms = threeDigits(now.millisecond);
    return '$h:$min:$sec.$ms';
  }

  static String _onlyTimeAndSinceStart(DateTime t) {
    var timeSinceStart = t.difference(PrettyPrinter.startTime!).toString();
    return '${onlyTime(t)} (+$timeSinceStart)';
  }

  static String _onlyDate(DateTime t) {
    String isoDate = t.toIso8601String();
    return isoDate.substring(0, isoDate.indexOf("T"));
  }

  static String _dateAndTime(DateTime t) {
    return "${_onlyDate(t)} ${_onlyTime(t)}";
  }
}
