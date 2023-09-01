import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../log_output.dart';
import '../output_event.dart';

/// Writes the log output to a file.
class FileOutput extends LogOutput {
  late final File _file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  FileOutput({
    required String path,
    this.overrideExisting = false,
    this.encoding = utf8,
  }) {
    _file = createFile(path);
  }

  @protected
  File createFile(String path) {
    return File(path);
  }

  @override
  Future<void> init() async {
    _sink = _file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    _sink?.write(event.output);
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
