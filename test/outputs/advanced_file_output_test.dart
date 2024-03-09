import 'dart:io';

import 'package:logger/logger.dart';
import 'package:test/test.dart';

void main() {
  var file = File("${Directory.systemTemp.path}/dart_advanced_logger_test.log");
  var dir = Directory("${Directory.systemTemp.path}/dart_advanced_logger_dir");
  setUp(() async {
    await file.create(recursive: true);
    await dir.create(recursive: true);
  });

  tearDown(() async {
    await file.delete();
    await dir.delete(recursive: true);
  });

  test('Real file read and write with buffer accumulation', () async {
    var output = AdvancedFileOutput(
      path: file.path,
      maxDelay: const Duration(milliseconds: 500),
      maxLogFileSizeMB: 0,
    );
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["First event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Second event"]);
    final event2 = OutputEvent(LogEvent(Level.info, ""), ["Third event"]);

    output.output(event0);
    output.output(event1);
    output.output(event2);

    //wait until buffer writes out to file
    await Future.delayed(const Duration(seconds: 1));

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

  test('Real file read and write with dynamic file names and immediate output',
      () async {
    var output = AdvancedFileOutput(
      path: dir.path,
      writeImmediately: [Level.info],
    );
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["First event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Second event"]);
    final event2 = OutputEvent(LogEvent(Level.info, ""), ["Third event"]);

    output.output(event0);
    output.output(event1);
    output.output(event2);

    final targetFile = output.targetFile;

    await output.destroy();

    var content = await targetFile?.readAsString();
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
