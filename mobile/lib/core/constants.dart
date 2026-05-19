class ApiConstants {
  // For web running on the same machine as uvicorn, use localhost.
  // For Android emulator we'd use 10.0.2.2 (special host loopback). We'll handle that later.
  static const String baseUrl = 'http://localhost:8000';
}
