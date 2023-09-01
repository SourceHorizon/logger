import 'dart:async';

import '../log_output.dart';
import '../output_event.dart';

class StreamOutput extends LogOutput {
  late StreamController<String> _controller;
  bool _shouldForward = false;

  StreamOutput() {
    _controller = StreamController<String>(
      onListen: () => _shouldForward = true,
      onPause: () => _shouldForward = false,
      onResume: () => _shouldForward = true,
      onCancel: () => _shouldForward = false,
    );
  }

  Stream<String> get stream => _controller.stream;

  @override
  void output(OutputEvent event) {
    if (!_shouldForward) {
      return;
    }

    _controller.add(event.output);
  }

  @override
  Future<void> destroy() {
    return _controller.close();
  }
}
