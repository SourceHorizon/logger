import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../log_level.dart';
import '../log_output.dart';
import '../output_event.dart';

extension _NumExt on num {
  String get twoDigits => toString().padLeft(2, '0');
  String get threeDigits => toString().padLeft(3, '0');
}

/// Writes the log output to a file.
class AdvancedFileOutput extends LogOutput {
  AdvancedFileOutput({
    this.directory,
    this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
    List<Level>? writeImmediately,
    this.maxDelay = const Duration(seconds: 2),
    this.maxBufferSize = 2000,
    this.maxLogFileSizeMB = 1,
  })  : writeImmediately = writeImmediately ??
            [
              Level.error,
              Level.fatal,
              Level.warning,
              // ignore: deprecated_member_use_from_same_package
              Level.wtf,
            ],
        assert(
          (file != null ? 1 : 0) + (directory != null ? 1 : 0) == 1,
          'Either file or directory must be set',
        );

  final File? file;
  final Directory? directory;

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

  bool get dynamicFilesMode => directory != null;
  File? get targetFile => _targetFile;

  @override
  Future<void> init() async {
    if (dynamicFilesMode) {
      //we use sync directory check to avoid losing
      //potential initial boot logs in early crash scenarios
      if (!directory!.existsSync()) {
        directory!.createSync(recursive: true);
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
      _sink?.writeAll(event.lines, Platform.lineTerminator);
      _sink?.writeln();
    }
    _buffer.clear();
  }

  Future<void> _updateTargetFile() async {
    if (!dynamicFilesMode) {
      await _openFile(file!);
      return;
    }

    final t = DateTime.now();
    final newName =
        '${t.year}-${t.month.twoDigits}-${t.day.twoDigits}_${t.hour.twoDigits}-${t.minute.twoDigits}-${t.second.twoDigits}-${t.millisecond.threeDigits}';
    if (_targetFile == null) {
      // just create a new file on first boot
      await _openFile(File('${directory!.path}/${newName}_init.txt'));
    } else {
      final proposed = File('${directory!.path}/${newName}_next.txt');
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
    _sink = _targetFile?.openWrite(
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
  }
}
