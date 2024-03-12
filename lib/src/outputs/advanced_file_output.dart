import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../log_level.dart';
import '../log_output.dart';
import '../output_event.dart';

extension _NumExt on num {
  String toDigits(int digits) => toString().padLeft(digits, '0');
}

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
    String initialFileName = 'latest.log',
    String Function(DateTime timestamp)? fileNameFormatter,
  })  : _path = path,
        _overrideExisting = overrideExisting,
        _encoding = encoding,
        _maxDelay = maxDelay,
        _maxFileSizeKB = maxFileSizeKB,
        _maxBufferSize = maxBufferSize,
        _initialFileName = initialFileName,
        _fileNameFormatter = fileNameFormatter ?? _defaultFileNameFormat,
        _writeImmediately = writeImmediately ??
            [
              Level.error,
              Level.fatal,
              Level.warning,
              // ignore: deprecated_member_use_from_same_package
              Level.wtf,
            ];

  /// Logs directory path by default, particular log file path if [_maxFileSizeKB] is 0
  final String _path;

  final bool _overrideExisting;
  final Encoding _encoding;

  final List<Level> _writeImmediately;
  final Duration _maxDelay;
  final int _maxFileSizeKB;
  final int _maxBufferSize;
  final String _initialFileName;
  final String Function(DateTime timestamp) _fileNameFormatter;

  IOSink? _sink;
  File? _targetFile;
  Timer? _bufferWriteTimer;
  Timer? _targetFileUpdater;

  final List<OutputEvent> _buffer = [];

  bool get _rotatingFilesMode => _maxFileSizeKB > 0;

  File? get currentFile => _targetFile;

  /// Formats the file with a full date string.
  ///
  /// Example:
  /// * `2024-01-01-10-05-02-123.log`
  static String _defaultFileNameFormat(DateTime t) {
    return '${t.year}-${t.month.toDigits(2)}-${t.day.toDigits(2)}'
        '-${t.hour.toDigits(2)}-${t.minute.toDigits(2)}-${t.second.toDigits(2)}'
        '-${t.millisecond.toDigits(3)}.log';
  }

  @override
  Future<void> init() async {
    if (_rotatingFilesMode) {
      final dir = Directory(_path);
      //we use sync directory check to avoid losing
      //potential initial boot logs in early crash scenarios
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      _targetFileUpdater = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _updateTargetFile(),
      );
    }

    _bufferWriteTimer = Timer.periodic(_maxDelay, (_) => _writeOutBuffer());
    await _updateTargetFile(); //run first setup without waiting for timer tick
  }

  @override
  void output(OutputEvent event) {
    _buffer.add(event);
    // If event level is present in writeImmediately, write out the buffer
    // along with any other possible elements that accumulated in it since
    // the last timer tick
    // Also write out if buffer is overfilled
    if (_buffer.length > _maxBufferSize ||
        _writeImmediately.contains(event.level)) {
      _writeOutBuffer();
    }
  }

  void _writeOutBuffer() {
    if (_sink == null) return; //wait until _sink becomes available
    for (final event in _buffer) {
      //
      _sink?.writeAll(event.lines, Platform.isWindows ? '\r\n' : '\n');
      _sink?.writeln();
    }
    _buffer.clear();
  }

  Future<void> _updateTargetFile() async {
    if (_targetFile == null) {
      //if logger wasn't destroyed properly, there may be a initial log file from the previous
      //session. we do this check to detect it and rename it to avoid overwriting
      final prev = File('$_path/${_getFileName(newFile: true)}');
      if (_rotatingFilesMode && await prev.exists()) {
        await prev.rename('$_path/${_getFileName()}.lost');
      }

      // just create a new file on first boot
      await _openNewFile();
    } else {
      try {
        if (await _targetFile!.length() > _maxFileSizeKB * 1024) {
          await _closeCurrentFile();
          await _openNewFile();
        }
      } catch (e, s) {
        print(e);
        print(s);
        // try creating another file and working with it
        await _closeCurrentFile();
        await _openNewFile();
      }
    }
  }

  Future<void> _openNewFile() async {
    _targetFile = File(
        _rotatingFilesMode ? '$_path/${_getFileName(newFile: true)}' : _path);
    _sink = _targetFile!.openWrite(
      mode: _overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: _encoding,
    );
  }

  Future<void> _closeCurrentFile() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null; //explicitly make null until assigned again
    if (_rotatingFilesMode) {
      await _targetFile?.rename('$_path/${_getFileName()}');
    }
  }

  String _getFileName({bool newFile = false}) {
    return newFile ? _initialFileName : _fileNameFormatter(DateTime.now());
  }

  @override
  Future<void> destroy() async {
    _bufferWriteTimer?.cancel();
    _targetFileUpdater?.cancel();
    try {
      _writeOutBuffer();
    } catch (e, s) {
      print('Failed to flush buffer before closing the logger: $e');
      print(s);
    }
    await _closeCurrentFile();
  }
}
