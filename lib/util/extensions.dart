extension DateTimeDiff on DateTime {
  /// Duration from [start] to this DateTime (this - start) in ms
  int since(DateTime start) => difference(start).inMilliseconds;
}
