/// Small, easy to use and extensible logger which prints beautiful logs.
library logger;

export 'src/outputs/file_output_stub.dart'
    if (dart.library.io) 'src/outputs/file_output.dart';
export 'src/outputs/advanced_file_output_stub.dart'
    if (dart.library.io) 'src/outputs/advanced_file_output.dart';
export 'web.dart';
