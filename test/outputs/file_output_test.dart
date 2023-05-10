import 'dart:io';

import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  var file = File("${Directory.systemTemp.path}/dart_logger_test.log");
  setUp(() async {
    await file.create(recursive: true);
  });

  tearDown(() async {
    await file.delete();
  });

  test('Real file read and write', () async {
    var output = FileOutput(file: file);
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, null), ["First event"]);
    final event1 = OutputEvent(LogEvent(Level.info, null), ["Second event"]);
    final event2 = OutputEvent(LogEvent(Level.info, null), ["Third event"]);

    output.output(event0);
    output.output(event1);
    output.output(event2);

    await output.destroy();

    var content = await file.readAsString();
    expect(
      content,
      allOf(
        contains("First event"),
        contains("Second event"),
        contains("Third event"),
      ),
    );
  });
}
