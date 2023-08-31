import '../log_output.dart';
import '../output_event.dart';

/// Logs simultaneously to multiple [LogOutput] outputs.
class MultiOutput extends LogOutput {
  late List<LogOutput> _outputs;

  MultiOutput(List<LogOutput?>? outputs) {
    _outputs = _normalizeOutputs(outputs);
  }

  List<LogOutput> _normalizeOutputs(List<LogOutput?>? outputs) {
    final normalizedOutputs = <LogOutput>[];

    if (outputs != null) {
      for (final output in outputs) {
        if (output != null) {
          normalizedOutputs.add(output);
        }
      }
    }

    return normalizedOutputs;
  }

  @override
  Future<void> init() async {
    await Future.wait(_outputs.map((e) => e.init()));
  }

  @override
  void output(OutputEvent event) {
    for (var o in _outputs) {
      o.output(event);
    }
  }

  @override
  Future<void> destroy() async {
    await Future.wait(_outputs.map((e) => e.destroy()));
  }
}
