import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

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
  ///
  /// [maxRotatedFilesCount] controls the number of rotated files to keep. By default
  /// is null, which means no limit.
  /// If set to a positive number, the output will keep the last
  /// [maxRotatedFilesCount] files. The deletion step will be executed by sorting
  /// files following the [fileSorter] ascending strategy and keeping the last files.
  /// The [latestFileName] will not be counted. The default [fileSorter] strategy is
  /// sorting by last modified date, beware that could be not reliable in some
  /// platforms and/or filesystems.
  ///
  /// [fileHeader] and [fileFooter] can be used to respectively add a header
  /// or footer to the file when opening/closing the file sink.
  /// (Please note that this happens not only when files are rotated but also
  /// on every start and shutdown of your application!)
  AdvancedFileOutput({
    required String path,
    bool overrideExisting = false,
    Encoding encoding = utf8,
    String? fileHeader,
    String? fileFooter,
    List<Level>? writeImmediately,
    Duration maxDelay = const Duration(seconds: 2),
    int maxBufferSize = 2000,
    int maxFileSizeKB = 1024,
    String latestFileName = 'latest.log',
    String Function(DateTime timestamp)? fileNameFormatter,
    int? maxRotatedFilesCount,
    Comparator<File>? fileSorter,
    Duration fileUpdateDuration = const Duration(minutes: 1),
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
