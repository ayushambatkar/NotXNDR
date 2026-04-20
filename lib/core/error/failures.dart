import 'exceptions.dart';

class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

Failure mapExceptionToFailure(Object error) {
  if (error is AppException) return Failure(error.message);
  return Failure('Unexpected error: $error');
}
