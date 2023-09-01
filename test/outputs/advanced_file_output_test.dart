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
      maxFileSizeKB: 0,
    );
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), "First event");
    final event1 = OutputEvent(LogEvent(Level.info, ""), "Second event");
    final event2 = OutputEvent(LogEvent(Level.info, ""), "Third event");

    output.output(event0);
    output.output(event1);
    output.output(event2);

    // Wait until buffer is flushed to file
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

  test('Real file read and write with rotating file names and immediate output',
      () async {
    var output = AdvancedFileOutput(
      path: dir.path,
      writeImmediately: [Level.info],
    );
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), "First event");
    final event1 = OutputEvent(LogEvent(Level.info, ""), "Second event");
    final event2 = OutputEvent(LogEvent(Level.info, ""), "Third event");

    output.output(event0);
    output.output(event1);
    output.output(event2);

    await output.destroy();

    final logFile = File('${dir.path}/latest.log');
    var content = await logFile.readAsString();
    expect(
      content,
      allOf(
        contains("First event"),
        contains("Second event"),
        contains("Third event"),
      ),
    );
  });

  test('Rolling files', () async {
    var output = AdvancedFileOutput(
      path: dir.path,
      maxFileSizeKB: 1,
    );
    await output.init();
    final event0 = OutputEvent(LogEvent(Level.fatal, ""), "1" * 1500);
    output.output(event0);
    await output.destroy();

    // Start again to roll files on init without waiting for timer tick
    await output.init();
    final event1 = OutputEvent(LogEvent(Level.fatal, ""), "2" * 1500);
    output.output(event1);
    await output.destroy();

    // And again for another roll
    await output.init();
    final event2 = OutputEvent(LogEvent(Level.fatal, ""), "3" * 1500);
    output.output(event2);
    await output.destroy();

    final files = dir.listSync();

    expect(
      files,
      (hasLength(3)),
    );
  });

  test('Flush temporary buffer on destroy', () async {
    var output = AdvancedFileOutput(path: dir.path);
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), "Last event");
    final event1 = OutputEvent(LogEvent(Level.info, ""), "Very last event");

    output.output(event0);
    output.output(event1);

    await output.destroy();

    final logFile = File('${dir.path}/latest.log');
    var content = await logFile.readAsString();
    expect(
      content,
      allOf(
        contains("Last event"),
        contains("Very last event"),
      ),
    );
  });
}
