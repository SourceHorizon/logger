import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../log_level.dart';
import '../log_output.dart';
import '../output_event.dart';

extension _NumExt on num {
  String toDigits(int digits) => toString().padLeft(digits, '0');
}

/// AdvancedFileOutput allows accumulating logs in a temporary buffer for
/// a short period [_maxDelay] of time before writing them out to a file,
/// resuling in less frequent writes. [_writeImmediately] list contains
/// the log levels that are written out immediately ([Level.warning],
/// [Level.error] and [Level.fatal] by default).
///
/// It also has a [_rotatingFilesMode] (enabled by default) that allows
/// automatically creating new log files on each [AdvancedFileOutput] init
/// or when the [_maxLogFileSizeMB] is reached. Set [_maxLogFileSizeMB] to 0
/// to disable this behaviour and treat [_path] as a particular file path
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
    String Function(DateTime, {required bool isLatest})? fileNameFormatter,
  })  : _path = path,
        _overrideExisting = overrideExisting,
        _encoding = encoding,
        _maxDelay = maxDelay,
        _maxLogFileSizeMB = maxLogFileSizeMB,
        _maxBufferSize = maxBufferSize,
        _fileNameFormatter = fileNameFormatter,
        _writeImmediately = writeImmediately ??
            [
              Level.error,
              Level.fatal,
              Level.warning,
              // ignore: deprecated_member_use_from_same_package
              Level.wtf,
            ];

  /// Logs directory path by default, particular log file path if [_maxLogFileSizeMB] is 0
  final String _path;

  final bool _overrideExisting;
  final Encoding _encoding;

  final List<Level> _writeImmediately;
  final Duration _maxDelay;
  final int _maxLogFileSizeMB;
  final int _maxBufferSize;
  final String Function(DateTime timestamp, {required bool isLatest})?
      _fileNameFormatter;

  IOSink? _sink;
  File? _targetFile;
  Timer? _bufferWriteTimer;
  Timer? _targetFileUpdater;

  final List<OutputEvent> _buffer = [];

  bool get _rotatingFilesMode => _maxLogFileSizeMB > 0;
  File? get currentFile => _targetFile;

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
      // just create a new file on first boot
      await _openNewFile();
    } else {
      try {
        if (await _targetFile!.length() > _maxLogFileSizeMB * 1000000) {
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
        _rotatingFilesMode ? '$_path/${_genFileName(isLatest: true)}' : _path);
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
      await _targetFile?.rename('$_path/${_genFileName(isLatest: false)}');
    }
  }

  String _genFileName({required bool isLatest}) {
    final t = DateTime.now();
    if (_fileNameFormatter != null) {
      return _fileNameFormatter!(t, isLatest: isLatest);
    } else {
      if (isLatest) {
        return 'latest.log';
      } else {
        return '${t.year}-${t.month.toDigits(2)}-${t.day.toDigits(2)}-${t.hour.toDigits(2)}-${t.minute.toDigits(2)}-${t.second.toDigits(2)}-${t.millisecond.toDigits(3)}.log';
      }
    }
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
