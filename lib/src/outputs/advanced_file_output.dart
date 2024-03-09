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
    required this.path,
    this.overrideExisting = false,
    this.encoding = utf8,
    List<Level>? writeImmediately,
    this.maxDelay = const Duration(seconds: 2),
    this.maxBufferSize = 2000,
    this.maxLogFileSizeMB = 1,
  }) : writeImmediately = writeImmediately ??
            [
              Level.error,
              Level.fatal,
              Level.warning,
              // ignore: deprecated_member_use_from_same_package
              Level.wtf,
            ];

  /// Logs directory path by default, particular log file path if [maxLogFileSizeMB] is 0
  final String path;

  final bool overrideExisting;
  final Encoding encoding;

  final List<Level> writeImmediately;
  final Duration maxDelay;
  final int maxLogFileSizeMB;
  final int maxBufferSize;

  IOSink? _sink;
  File? _targetFile;
  Timer? _bufferWriteTimer;
  Timer? _targetFileUpdater;

  final List<OutputEvent> _buffer = [];

  bool get rotatingFilesMode => maxLogFileSizeMB > 0;
  File? get targetFile => _targetFile;

  @override
  Future<void> init() async {
    if (rotatingFilesMode) {
      final dir = Directory(path);
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

    _bufferWriteTimer = Timer.periodic(maxDelay, (_) => _writeOutBuffer());
    await _updateTargetFile(); //run first setup without waiting for timer tick
  }

  @override
  void output(OutputEvent event) {
    _buffer.add(event);
    // If event level is present in writeImmediately, write out the buffer
    // along with any other possible elements that accumulated in it since
    // the last timer tick
    // Also write out if buffer is overfilled
    if (_buffer.length > maxBufferSize ||
        writeImmediately.contains(event.level)) {
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
    if (!rotatingFilesMode) {
      await _openFile(File(path));
      return;
    }

    final t = DateTime.now();
    final newName =
        '${t.year}-${t.month.toDigits(2)}-${t.day.toDigits(2)}_${t.hour.toDigits(2)}-${t.minute.toDigits(2)}-${t.second.toDigits(2)}-${t.millisecond.toDigits(3)}';
    if (_targetFile == null) {
      // just create a new file on first boot
      await _openFile(File('$path/${newName}_init.txt'));
    } else {
      final proposed = File('$path/${newName}_next.txt');
      try {
        if (await _targetFile!.length() > maxLogFileSizeMB * 1000000) {
          await _closeCurrentFile();
          await _openFile(proposed);
        }
      } catch (e) {
        // try creating another file and working with it
        await _closeCurrentFile();
        await _openFile(proposed);
      }
    }
  }

  Future<void> _openFile(File proposed) async {
    _targetFile = proposed;
    _sink = _targetFile!.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  Future<void> _closeCurrentFile() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null; //explicitly make null until assigned again
  }

  @override
  Future<void> destroy() async {
    _bufferWriteTimer?.cancel();
    _targetFileUpdater?.cancel();
    await _closeCurrentFile();
    _buffer.clear();
  }
}
