import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/widgets/logger_view.dart';

void main() {
  runApp(const FlutterLoggerDevToolsExtension());
}

class FlutterLoggerDevToolsExtension extends StatelessWidget {
  const FlutterLoggerDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(child: const LoggerView());
  }
}
