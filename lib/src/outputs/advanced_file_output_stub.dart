import 'dart:convert';
import 'dart:io';

import '../log_level.dart';
import '../log_output.dart';
import '../output_event.dart';

/// Writes the log output to a file.
class AdvancedFileOutput extends LogOutput {
  AdvancedFileOutput({
    Directory? directory,
    File? file,
    bool overrideExisting = false,
    Encoding encoding = utf8,
    List<Level>? writeImmediately,
    Duration maxDelay = const Duration(seconds: 2),
    int maxBufferSize = 2000,
    int maxLogFileSizeMB = 1,
  }) {
    throw UnsupportedError("Not supported on this platform.");
  }

  File? get targetFile => null;

  @override
  void output(OutputEvent event) {
    throw UnsupportedError("Not supported on this platform.");
  }
}
