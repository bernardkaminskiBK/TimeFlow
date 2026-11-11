abstract interface class ElapsedTimeSource {
  Duration get elapsed;

  void start();

  void stop();

  void reset();
}

class SystemElapsedTimeSource implements ElapsedTimeSource {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  Duration get elapsed => _stopwatch.elapsed;

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();

  @override
  void reset() => _stopwatch.reset();
}
