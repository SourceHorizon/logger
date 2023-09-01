import 'package:logger/logger.dart';

var logger = Logger(
  printers: [PrettyPrinter()],
);

var loggerNoStack = Logger(
  printers: [PrettyPrinter(methodCount: 0)],
);

void main() {
  print(
      'Run with either `dart example/main.dart` or `dart --enable-asserts example/main.dart`.');
  demo();
}

void demo() {
  logger.d('Log message with 2 methods');

  loggerNoStack.i('Info message');

  loggerNoStack.w('Just a warning!');

  logger.e('Error! Something bad happened', error: 'Test Error');

  loggerNoStack.t({'key': 5, 'value': 'something'});

  Logger(printers: [SimplePrinter(colors: true)]).t('boom');

  Logger(printers: [
    PrefixPrinter(),
    PrettyPrinter(colors: true, printTime: true),
  ]).w('This log has a prefix');
}
