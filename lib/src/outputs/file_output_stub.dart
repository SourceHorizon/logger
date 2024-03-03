import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

import '../log_output.dart';
import '../output_event.dart';

/// Writes the log output to a file.
class FileOutput extends LogOutput {
  FileOutput({
    required String path,
    bool overrideExisting = false,
    Encoding encoding = utf8,
  }) {
    throw UnsupportedError("Not supported on this platform.");
  }

  @protected
  File createFile(String path) {
    throw UnsupportedError("Not supported on this platform.");
  }

  @override
  void output(OutputEvent event) {
    throw UnsupportedError("Not supported on this platform.");
  }
}
