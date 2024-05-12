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

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["First event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Second event"]);
    final event2 = OutputEvent(LogEvent(Level.info, ""), ["Third event"]);

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

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["First event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Second event"]);
    final event2 = OutputEvent(LogEvent(Level.info, ""), ["Third event"]);

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
    final event0 = OutputEvent(LogEvent(Level.fatal, ""), ["1" * 1500]);
    output.output(event0);
    await output.destroy();

    // Start again to roll files on init without waiting for timer tick
    await output.init();
    final event1 = OutputEvent(LogEvent(Level.fatal, ""), ["2" * 1500]);
    output.output(event1);
    await output.destroy();

    // And again for another roll
    await output.init();
    final event2 = OutputEvent(LogEvent(Level.fatal, ""), ["3" * 1500]);
    output.output(event2);
    await output.destroy();

    final files = dir.listSync();

    expect(
      files,
      (hasLength(3)),
    );
  });

  test('Rolling files with rotated files deletion', () async {
    var output = AdvancedFileOutput(
      path: dir.path,
      maxFileSizeKB: 1,
      maxRotatedFilesCount: 1,
    );

    await output.init();
    final event0 = OutputEvent(LogEvent(Level.fatal, ""), ["1" * 1500]);
    output.output(event0);
    await output.destroy();

    // TODO Find out why test is so flaky with durations <1000ms
    // Give the OS a chance to flush to the file system (should reduce flakiness)
    await Future.delayed(const Duration(milliseconds: 1000));

    // Start again to roll files on init without waiting for timer tick
    await output.init();
    final event1 = OutputEvent(LogEvent(Level.fatal, ""), ["2" * 1500]);
    output.output(event1);
    await output.destroy();

    await Future.delayed(const Duration(milliseconds: 1000));

    // And again for another roll
    await output.init();
    final event2 = OutputEvent(LogEvent(Level.fatal, ""), ["3" * 1500]);
    output.output(event2);
    await output.destroy();

    await Future.delayed(const Duration(milliseconds: 1000));

    final files = dir.listSync();

    // Expect only 2 files: the "latest" that is the current log file
    // and only one rotated file. The first created file should be deleted.
    expect(files, hasLength(2));
    final latestFile = File('${dir.path}/latest.log');
    final rotatedFile = dir
        .listSync()
        .whereType<File>()
        .firstWhere((file) => file.path != latestFile.path);
    expect(await latestFile.readAsString(), contains("3"));
    expect(await rotatedFile.readAsString(), contains("2"));
  });

  test('Rolling files with custom file sorter', () async {
    var output = AdvancedFileOutput(
      path: dir.path,
      maxFileSizeKB: 1,
      maxRotatedFilesCount: 1,
      // Define a custom file sorter that sorts files by their length
      // (strange behavior for testing purposes) from the longest to
      // the shortest: the longest file should be deleted first.
      fileSorter: (a, b) => b.lengthSync().compareTo(a.lengthSync()),
    );

    await output.init();
    final event0 = OutputEvent(LogEvent(Level.fatal, ""), ["1" * 1500]);
    output.output(event0);
    await output.destroy();

    // Start again to roll files on init without waiting for timer tick
    await output.init();
    // Create a second file with a greater length (it should be deleted first)
    final event1 = OutputEvent(LogEvent(Level.fatal, ""), ["2" * 3000]);
    output.output(event1);
    await output.destroy();

    // Give the OS a chance to flush to the file system (should reduce flakiness)
    await Future.delayed(const Duration(milliseconds: 50));

    // And again for another roll
    await output.init();
    final event2 = OutputEvent(LogEvent(Level.fatal, ""), ["3" * 1500]);
    output.output(event2);
    await output.destroy();

    final files = dir.listSync();

    // Expect only 2 files: the "latest" that is the current log file
    // and only one rotated file (the shortest one).
    expect(files, hasLength(2));
    final latestFile = File('${dir.path}/latest.log');
    final rotatedFile = dir
        .listSync()
        .whereType<File>()
        .firstWhere((file) => file.path != latestFile.path);
    expect(await latestFile.readAsString(), contains("3"));
    expect(await rotatedFile.readAsString(), contains("1"));
  });

  test('Flush temporary buffer on destroy', () async {
    var output = AdvancedFileOutput(path: dir.path);
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["Last event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Very last event"]);

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
