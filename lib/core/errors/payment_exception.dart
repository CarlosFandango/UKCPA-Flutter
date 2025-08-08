/// Custom exception for payment-related errors
class PaymentException implements Exception {
  final String message;
  final String code;
  final String? details;
  final bool isUserCancellation;

  const PaymentException({
    required this.message,
    required this.code,
    this.details,
    this.isUserCancellation = false,
  });

  @override
  String toString() => 'PaymentException: $message (code: $code)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentException &&
        other.message == message &&
        other.code == code &&
        other.details == details &&
        other.isUserCancellation == isUserCancellation;
  }

  @override
  int get hashCode {
    return message.hashCode ^
        code.hashCode ^
        details.hashCode ^
        isUserCancellation.hashCode;
  }
}