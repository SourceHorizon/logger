import 'dart:convert';

import '../log_level.dart';
import '../log_output.dart';
import '../output_event.dart';

/// Accumulates logs in a buffer to reduce frequent disk, writes while optionally
/// switching to a new log file if it reaches a certain size.
///
/// [AdvancedFileOutput] offer various improvements over the original
/// [FileOutput]:
/// * Managing an internal buffer which collects the logs and only writes
/// them after a certain period of time to the disk.
/// * Dynamically switching log files instead of using a single one specified
/// by the user, when the current file reaches a specified size limit (optionally).
///
/// The buffered output can significantly reduce the
/// frequency of file writes, which can be beneficial for (micro-)SD storage
/// and other types of low-cost storage (e.g. on IoT devices). Specific log
/// levels can trigger an immediate flush, without waiting for the next timer
/// tick.
///
/// New log files are created when the current file reaches the specified size
/// limit. This is useful for writing "archives" of telemetry data and logs
/// while keeping them structured.
class AdvancedFileOutput extends LogOutput {
  /// Creates a buffered file output.
  ///
  /// By default, the log is buffered until either the [maxBufferSize] has been
  /// reached, the timer controlled by [maxDelay] has been triggered or an
  /// [OutputEvent] contains a [writeImmediately] log level.
  ///
  /// [maxFileSizeKB] controls the log file rotation. The output automatically
  /// switches to a new log file as soon as the current file exceeds it.
  /// Use -1 to disable log rotation.
  ///
  /// [maxDelay] describes the maximum amount of time before the buffer has to be
  /// written to the file.
  ///
  /// Any log levels that are specified in [writeImmediately] trigger an immediate
  /// flush to the disk ([Level.warning], [Level.error] and [Level.fatal] by default).
  ///
  /// [path] is either treated as directory for rotating or as target file name,
  /// depending on [maxFileSizeKB].
  AdvancedFileOutput({
    required String path,
    bool overrideExisting = false,
    Encoding encoding = utf8,
    List<Level>? writeImmediately,
    Duration maxDelay = const Duration(seconds: 2),
    int maxBufferSize = 2000,
    int maxFileSizeKB = 1024,
    String latestFileName = 'latest.log',
    String Function(DateTime timestamp)? fileNameFormatter,
  }) {
    throw UnsupportedError("Not supported on this platform.");
  }

  @override
  void output(OutputEvent event) {
    throw UnsupportedError("Not supported on this platform.");
  }
}
