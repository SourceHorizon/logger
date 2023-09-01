import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  test('should print an emoji when option is enabled', () {
    final expectedMessage = 'some message with an emoji';
    final emojiPrettyPrinter = PrettyPrinter(printEmojis: true);

    final event = LogEvent(
      Level.debug,
      expectedMessage,
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    final actualLog = emojiPrettyPrinter.log(event.message, event);
    expect(actualLog, contains(PrettyPrinter.defaultLevelEmojis[Level.debug]));
    expect(actualLog, contains(expectedMessage));
  });

  test('should print custom emoji or fallback', () {
    final expectedMessage = 'some message with an emoji';
    final emojiPrettyPrinter = PrettyPrinter(
      printEmojis: true,
      levelEmojis: {
        Level.debug: '🧵',
      },
    );

    final firstEvent = LogEvent(
      Level.debug,
      expectedMessage,
      error: 'some error',
      stackTrace: StackTrace.current,
    );
    final emojiLog = emojiPrettyPrinter.log(firstEvent.message, firstEvent);
    expect(
      emojiLog,
      contains(
          '${emojiPrettyPrinter.levelEmojis![Level.debug]!} $expectedMessage'),
    );

    final secondEvent = LogEvent(
      Level.info,
      expectedMessage,
      error: 'some error',
      stackTrace: StackTrace.current,
    );
    final fallbackEmojiLog =
        emojiPrettyPrinter.log(secondEvent.message, secondEvent);
    expect(
      fallbackEmojiLog,
      contains(
          '${PrettyPrinter.defaultLevelEmojis[Level.info]!} $expectedMessage'),
    );
  });

  test('should print custom color or fallback', () {
    final expectedMessage = 'some message with a color';
    final coloredPrettyPrinter = PrettyPrinter(
      colors: true,
      levelColors: {
        Level.debug: const AnsiColor.fg(50),
      },
    );

    final firstEvent = LogEvent(
      Level.debug,
      expectedMessage,
      error: 'some error',
      stackTrace: StackTrace.current,
    );
    final coloredLog = coloredPrettyPrinter.log(firstEvent.message, firstEvent);
    expect(coloredLog, contains(expectedMessage));
    expect(
      coloredLog,
      startsWith(coloredPrettyPrinter.levelColors![Level.debug]!.toString()),
    );

    final secondEvent = LogEvent(
      Level.info,
      expectedMessage,
      error: 'some error',
      stackTrace: StackTrace.current,
    );
    final fallbackColoredLog =
        coloredPrettyPrinter.log(secondEvent.message, secondEvent);
    expect(fallbackColoredLog, contains(expectedMessage));
    expect(
      fallbackColoredLog,
      startsWith(PrettyPrinter.defaultLevelColors[Level.info]!.toString()),
    );
  });

  test('deal with string type message', () {
    final prettyPrinter = PrettyPrinter();
    final expectedMessage = 'normally computed message';
    final withFunction = LogEvent(
      Level.debug,
      expectedMessage,
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    final actualLog = prettyPrinter.log(withFunction.message, withFunction);
    expect(
      actualLog,
      contains(expectedMessage),
    );
  });

  test('deal with Map type message', () {
    final prettyPrinter = PrettyPrinter();
    final expectedMsgMap = {'foo': 123, 1: 2, true: 'false'};
    var withMap = LogEvent(
      Level.debug,
      prettyPrinter.stringifyMessage(expectedMsgMap),
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    final actualLog = prettyPrinter.log(withMap.message, withMap);
    for (var expectedMsg in expectedMsgMap.entries) {
      expect(
        actualLog,
        contains('${expectedMsg.key}: ${expectedMsg.value}'),
      );
    }
  });

  test('deal with Iterable type message', () {
    final prettyPrinter = PrettyPrinter();
    final expectedMsgItems = ['first', 'second', 'third', 'last'];
    var withIterable = LogEvent(
      Level.debug,
      prettyPrinter.stringifyMessage(['first', 'second', 'third', 'last']),
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    final actualLog = prettyPrinter.log(withIterable.message, withIterable);
    for (var expectedMsg in expectedMsgItems) {
      expect(
        actualLog,
        contains(expectedMsg),
      );
    }
  });

  test('stackTraceBeginIndex', () {
    final prettyPrinter = PrettyPrinter(
      stackTraceBeginIndex: 2,
    );
    final withFunction = LogEvent(
      Level.debug,
      "some message",
      error: 'some error',
      stackTrace: StackTrace.current,
    );

    final actualLog = prettyPrinter.log(withFunction.message, withFunction);
    expect(
      actualLog,
      allOf([
        isNot(contains("#0   ")),
        isNot(contains("#1   ")),
        contains("#2   "),
      ]),
    );
  });
}
