import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/widgets/logger_view.dart';

void main() {
  runApp(const FlutterLoggerDevToolsExtension());
}

class FlutterLoggerDevToolsExtension extends StatelessWidget {
  const FlutterLoggerDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(
      child: Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Theme.of(context).brightness,
          ),
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        ),
        child: const LoggerView(),
      ),
    );
  }
}
