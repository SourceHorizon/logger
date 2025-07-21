import 'dart:io';

import 'package:file/memory.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

var memory = MemoryFileSystem();

class MemoryAdvancedFileOutput extends AdvancedFileOutput {
  MemoryAdvancedFileOutput({
    required super.path,
    super.maxDelay,
    super.maxFileSizeKB,
    super.writeImmediately,
    super.maxRotatedFilesCount,
    super.fileNameFormatter,
    super.fileSorter,
    super.fileHeader,
    super.fileFooter,
  });

  late File _file;

  get file => _file;

  @override
  File createFile(String path) {
    return _file = memory.file(path);
  }
}

void main() {
  final fileName = "dart_advanced_logger_test.log";
  final dirName = "dart_advanced_logger_dir";

  tearDown(() {
    var file = memory.file(fileName);
    if (file.existsSync()) {
      file.deleteSync();
    }

    var directory = memory.directory(dirName);
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('Real file read and write with buffer accumulation', () async {
    var output = MemoryAdvancedFileOutput(
      path: fileName,
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

    await output.destroy();

    var content = await output.file.readAsString();
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
    var output = MemoryAdvancedFileOutput(
      path: dirName,
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

    var content = await output.file.readAsString();
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
    var output = MemoryAdvancedFileOutput(
      path: dirName,
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

    final files = output.file.parent.listSync();
    expect(
      files,
      (hasLength(3)),
    );
  });

  test('Rolling files with rotated files deletion', () async {
    var output = MemoryAdvancedFileOutput(
      path: dirName,
      maxFileSizeKB: 1,
      maxRotatedFilesCount: 1,
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

    final latestFile = output.file;
    final files = latestFile.parent.listSync();
    // Expect only 2 files: the "latest" that is the current log file
    // and only one rotated file. The first created file should be deleted.
    expect(files, hasLength(2));

    final rotatedFile = files
        .whereType<File>()
        .firstWhere((file) => file.path != latestFile.path);
    expect(await latestFile.readAsString(), contains("3"));
    expect(await rotatedFile.readAsString(), contains("2"));
  });

  test('Rolling files with header/footer', () async {
    const fileHeader = "TEST-HEADER";
    const fileFooter = "TEST-FOOTER";

    var output = MemoryAdvancedFileOutput(
      path: dirName,
      maxFileSizeKB: 1,
      maxRotatedFilesCount: 1,
      fileHeader: fileHeader,
      fileFooter: fileFooter,
    );

    await output.init();
    final event0 =
        OutputEvent(LogEvent(Level.fatal, ""), ["Header and Footer Test"]);
    output.output(event0);
    await output.destroy();

    final latestFile = output.file;
    expect(await latestFile.readAsString(), startsWith(fileHeader));
    expect(await latestFile.readAsString(), endsWith("$fileFooter\n"));
  });

  test('Rolling files with custom file sorter', () async {
    int fileNameCounter = 0;
    var output = MemoryAdvancedFileOutput(
      path: dirName,
      maxFileSizeKB: 1,
      maxRotatedFilesCount: 1,
      // Define a custom file sorter that sorts files by their length
      // (strange behavior for testing purposes) from the longest to
      // the shortest: the longest file should be deleted first.
      fileSorter: (a, b) => b.lengthSync().compareTo(a.lengthSync()),
      // The default uses date time until milliseconds and sometimes this test is faster and would re-use the same name multiple times.
      fileNameFormatter: (timestamp) => "${fileNameCounter++}.log",
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

    // And again for another roll
    await output.init();
    final event2 = OutputEvent(LogEvent(Level.fatal, ""), ["3" * 1500]);
    output.output(event2);
    await output.destroy();

    final latestFile = output.file;
    final files = latestFile.parent.listSync();
    // Expect only 2 files: the "latest" that is the current log file
    // and only one rotated file (the shortest one).
    expect(files, hasLength(2));

    final rotatedFile = files
        .whereType<File>()
        .firstWhere((file) => file.path != latestFile.path);
    expect(await latestFile.readAsString(), contains("3"));
    expect(await rotatedFile.readAsString(), contains("1"));
  });

  test('Flush temporary buffer on destroy', () async {
    var output = MemoryAdvancedFileOutput(path: dirName);
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["Last event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Very last event"]);

    output.output(event0);
    output.output(event1);

    await output.destroy();

    var content = await output.file.readAsString();
    expect(
      content,
      allOf(
        contains("Last event"),
        contains("Very last event"),
      ),
    );
  });
}
