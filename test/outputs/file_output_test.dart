import 'package:file/memory.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

var memory = MemoryFileSystem();

void main() {
  final file = memory.file("dart_logger_test.log");

  tearDown(() {
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  test('Real file read and write', () async {
    var output = FileOutput(file: file);
    await output.init();

    final event0 = OutputEvent(LogEvent(Level.info, ""), ["First event"]);
    final event1 = OutputEvent(LogEvent(Level.info, ""), ["Second event"]);
    final event2 = OutputEvent(LogEvent(Level.info, ""), ["Third event"]);

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
