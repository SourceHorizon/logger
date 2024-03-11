import 'dart:convert';
import 'dart:io';

import '../log_level.dart';
import '../log_output.dart';
import '../output_event.dart';

/// AdvancedFileOutput allows accumulating logs in a temporary buffer for
/// a short period [maxDelay] of time before writing them out to a file,
/// resuling in less frequent writes. [writeImmediately] list contains
/// the log levels that are written out immediately ([Level.warning],
/// [Level.error] and [Level.fatal] by default).
///
/// It also has a [rotatingFilesMode] (enabled by default) that allows
/// automatically creating new log files on each [AdvancedFileOutput] init
/// or when the [maxLogFileSizeMB] is reached. Set [maxLogFileSizeMB] to 0
/// to disable this behaviour and treat [path] as a particular file path
/// rather than a directory for auto-created logs.
class AdvancedFileOutput extends LogOutput {
  AdvancedFileOutput({
    required String path,
    bool overrideExisting = false,
    Encoding encoding = utf8,
    List<Level>? writeImmediately,
    Duration maxDelay = const Duration(seconds: 2),
    int maxBufferSize = 2000,
    int maxLogFileSizeMB = 1,
    String Function(DateTime timestamp, {required bool isLatest})?
        fileNameFormatter,
  }) {
    throw UnsupportedError("Not supported on this platform.");
  }

  File? get currentFile =>
      throw UnsupportedError("Not supported on this platform.");

  @override
  void output(OutputEvent event) {
    throw UnsupportedError("Not supported on this platform.");
  }
}
