class ApiError {
  final String message;
  final int? statusCode;

  /// True when this failure means "the request never reached the server or
  /// got no response back" — no signal, a dropped connection, a timed-out
  /// socket — as opposed to the server answering with an error.
  ///
  /// Callers use this to tell a real connectivity problem apart from an
  /// authentication or server error, which look identical if you only read
  /// [message]. A screen that reacted to "the profile fetch failed" by
  /// signing the student out used to do that even while offline — this flag
  /// is what lets it ask "was it actually a connectivity problem?" first.
  final bool isConnectivityIssue;

  ApiError({
    required this.message,
    this.statusCode,
    this.isConnectivityIssue = false,
  });

  @override
  String toString() {
    return message;
  }
}
