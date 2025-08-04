/// Utility class for formatting money amounts
class MoneyFormatter {
  /// Format pence amount to currency string (£X.XX)
  static String formatPence(int pence) {
    final pounds = pence / 100;
    return '£${pounds.toStringAsFixed(2)}';
  }

  /// Format pounds amount to currency string (£X.XX)
  static String formatPounds(double pounds) {
    return '£${pounds.toStringAsFixed(2)}';
  }

  /// Convert pence to pounds
  static double penceToPounds(int pence) {
    return pence / 100;
  }

  /// Convert pounds to pence
  static int poundsToPence(double pounds) {
    return (pounds * 100).round();
  }

  /// Format price range from pence amounts
  static String formatPriceRange(int? minPence, int? maxPence) {
    if (minPence == null && maxPence == null) {
      return 'Price on request';
    }
    
    if (minPence != null && maxPence != null) {
      if (minPence == maxPence) {
        return formatPence(minPence);
      } else {
        return '${formatPence(minPence)} - ${formatPence(maxPence)}';
      }
    }
    
    if (minPence != null) {
      return 'From ${formatPence(minPence)}';
    }
    
    if (maxPence != null) {
      return 'Up to ${formatPence(maxPence)}';
    }
    
    return 'Price on request';
  }

  /// Check if amount is free
  static bool isFree(int pence) {
    return pence == 0;
  }

  /// Format free amount
  static String formatFree() {
    return 'Free';
  }

  /// Format amount with free check
  static String formatPenceWithFreeCheck(int pence) {
    return isFree(pence) ? formatFree() : formatPence(pence);
  }
}