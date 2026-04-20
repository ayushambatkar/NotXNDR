class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class PermissionException extends AppException {
  const PermissionException(super.message);
}

class HashMismatchException extends AppException {
  const HashMismatchException(super.message);
}
