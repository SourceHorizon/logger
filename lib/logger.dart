/// Small, easy to use and extensible logger which prints beautiful logs.
library logger;

export 'logger_web_safe.dart';

export 'src/outputs/file_output_stub.dart'
    if (dart.library.io) 'src/outputs/file_output.dart';
