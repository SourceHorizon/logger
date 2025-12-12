## 2.6.2

* PrettyPrinter: Fixed the showing of internal `package:logger` log lines in the stack trace on Flutter/Dart Web.
  Closes [#102](https://github.com/SourceHorizon/logger/issues/102).
* Lowered the `meta` package version requirement.

## 2.6.1

* AdvancedFileOutput: Fixed race condition while flushing the buffer (`StateError`).
  Closes [#99](https://github.com/SourceHorizon/logger/issues/99), thanks to @sap1tz.

## 2.6.0

* Added log level comparison operators. Thanks to
  @busslina ([#90](https://github.com/SourceHorizon/logger/pull/90)).
* AdvancedFileOutput: Added `fileHeader` and `fileFooter` options.
  Closes [#97](https://github.com/SourceHorizon/logger/issues/97).

## 2.5.0

* AdvancedFileOutput: Added support for custom `fileUpdateDuration`. Thanks to
  @shlowdy ([#86](https://github.com/SourceHorizon/logger/pull/86)).
* README: Fixed outdated LogOutput documentation.

## 2.4.0

* Added pub.dev `topics`. Thanks to
  @jonasfj ([#74](https://github.com/SourceHorizon/logger/pull/74)).
* PrettyPrinter: Added `dateTimeFormat` option (backwards-compatible with `printTime`).
  Fixes [#80](https://github.com/SourceHorizon/logger/issues/80).

## 2.3.0

* AdvancedFileOutput: Added file deletion option. Thanks to
  @lomby92 ([#71](https://github.com/SourceHorizon/logger/pull/71)).

## 2.2.0

* Added AdvancedFileOutput. Thanks to
  @pyciko ([#65](https://github.com/SourceHorizon/logger/pull/65)).
* Added missing acknowledgments in README.

## 2.1.0

* Improved README explanation about debug mode. Thanks to
  @gkuga ([#57](https://github.com/SourceHorizon/logger/pull/57)).
* Added web safe export. Fixes [#58](https://github.com/SourceHorizon/logger/issues/58).
* Added `logger.init` to optionally await any `async` `init()` methods.
  Fixes [#61](https://github.com/SourceHorizon/logger/issues/61).

## 2.0.2+1

* Meta update: Updated repository links to https://github.com/SourceHorizon/logger.

## 2.0.2

* Moved the default log level assignment to prevent weird lazy initialization bugs.
  Mitigates [#38](https://github.com/SourceHorizon/logger/issues/38).

## 2.0.1

* Updated README to reflect v2.0.0 log signature change.

## 2.0.0

* Fixed supported platforms list.
* Removed reference to outdated `logger_flutter` project.
  Thanks to @yangsfang ([#32](https://github.com/SourceHorizon/logger/pull/32)).
* Added override capability for logger defaults.
  Thanks to @yangsfang ([#34](https://github.com/SourceHorizon/logger/pull/34)).
* `Level.verbose`, `Level.wtf` and `Level.nothing` have been deprecated and are replaced
  by `Level.trace`, `Level.fatal` and `Level.off`.
  Additionally `Level.all` has been added.
* PrettyPrinter: Added `levelColors` and `levelEmojis` as constructor parameter.

### Breaking changes

* `log` signature has been changed to closer match dart's developer `log` function and allow for
  future optional parameters.

  Additionally, `time` has been added as an optional named parameter to support providing custom
  timestamps for LogEvents instead of `DateTime.now()`.

  #### Migration:
    * Before:
      ```dart
      logger.e("An error occurred!", error, stackTrace);
      ```
    * After:
      ```dart
      logger.e("An error occurred!", error: error, stackTrace: stackTrace);
      ```
* `init` and `close` methods of `LogFilter`, `LogOutput` and `LogPrinter` are now async along
  with `Logger.close()`. (Fixes FileOutput)
* LogListeners are now called on every LogEvent independent of the filter.
* PrettyPrinter: `includeBox` is now private.
* PrettyPrinter: `errorMethodCount` is now only considered if an error has been provided.
  Otherwise `methodCount` is used.
* PrettyPrinter: Static `levelColors` and `levelEmojis` have been renamed to `defaultLevelColors`
  and `defaultLevelEmojis` and are used as fallback for their respective constructor parameters.
* Levels are now sorted by their respective value instead of the enum index (Order didn't change).

## 1.4.0

* Bumped upper SDK constraint to `<4.0.0`.
* Added `excludePaths` to PrettyPrinter. Thanks to
  @Stitch-Taotao ([#13](https://github.com/SourceHorizon/logger/pull/13)).
* Removed background color for `Level.error` and `Level.wtf` to improve readability.
* Improved PrettyPrinter documentation.
* Corrected README notice about ANSI colors.

## 1.3.0

* Fixed stackTrace count when using `stackTraceBeginIndex`.
  Addresses [#114](https://github.com/simc/logger/issues/114).
* Added proper FileOutput stub. Addresses [#94](https://github.com/simc/logger/issues/94).
* Added `isClosed`. Addresses [#130](https://github.com/simc/logger/issues/130).
* Added `time` to LogEvent.
* Added `error` handling to LogfmtPrinter.

## 1.2.2

* Fixed conditional LogOutput export. Credits to
  @ChristopheOosterlynck [#4](https://github.com/SourceHorizon/logger/pull/4).

## 1.2.1

* Reverted `${this}` interpolation and added linter
  ignore. [#1](https://github.com/SourceHorizon/logger/issues/1)

## 1.2.0

* Added origin LogEvent to OutputEvent. Addresses [#133](https://github.com/simc/logger/pull/133).
* Re-added LogListener and OutputListener (Should restore compatibility with logger_flutter).
* Replaced pedantic with lints.

## 1.1.0

* Enhance boxing control with PrettyPrinter. Credits to @timmaffett
* Add trailing new line to FileOutput. Credits to @narumishi
* Add functions as a log message. Credits to @smotastic

## 1.0.0

* Stable nullsafety

## 1.0.0-nullsafety.0

* Convert to nullsafety. Credits to @DevNico

## 0.9.4

* Remove broken platform detection.

## 0.9.3

* Add `MultiOutput`. Credits to @gmpassos.
* Handle browser Dart stacktraces in PrettyPrinter. Credits to @gmpassos.
* Add platform detection. Credits to @gmpassos.
* Catch output exceptions. Credits to @gmpassos.
* Several documentation fixes. Credits to @gmpassos.

## 0.9.2

* Add `PrefixPrinter`. Credits to @tkutcher.
* Add `HybridPrinter`. Credits to @tkutcher.

## 0.9.1

* Fix logging output for Flutter Web. Credits to @nateshmbhat and @Cocotus.

## 0.9.0

* Remove `OutputCallback` and `LogCallback`
* Rename `SimplePrinter`s argument `useColor` to `colors`
* Rename `DebugFilter` to `DevelopmentFilter`

## 0.8.3

* Add LogfmtPrinter
* Add colored output to SimplePrinter

## 0.8.2

* Add StreamOutput

## 0.8.1

* Deprecate callbacks

## 0.8.0

* Fix SimplePrinter showTime #12
* Remove buffer field
* Update library structure (thanks @marcgraub!)

## 0.7.0+2

* Remove screenshot

## 0.7.0+1

* Fix pedantic

## 0.7.0

* Added `ProductionFilter`, `FileOutput`, `MemoryOutput`, `SimplePrinter`
* Breaking: Changed `LogFilter`, `LogPrinter` and `LogOutput`

## 0.6.0

* Added option to output timestamp
* Added option to disable color
* Added `LogOutput`
* Behaviour change of `LogPrinter`
* Remove dependency

## 0.5.0

* Added emojis
* `LogFilter` is a class now

## 0.4.0

* First version of the new logger
