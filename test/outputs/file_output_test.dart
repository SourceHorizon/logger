import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logger/logger.dart';
import 'package:test/test.dart';

var memory = MemoryFileSystem();

class MemoryFileOutput extends FileOutput {
  MemoryFileOutput({
    required super.path,
    super.encoding,
    super.overrideExisting,
  });

  late File _file;

  get file => _file;

  @override
  File createFile(String path) {
    return _file = memory.file(path);
  }
}

void main() {
  final fileName = "dart_logger_test.log";

  tearDown(() {
    var file = memory.file(fileName);
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  test('Real file read and write', () async {
    var output = MemoryFileOutput(path: fileName);
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
}
