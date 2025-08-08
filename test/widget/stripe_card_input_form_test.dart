import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:ukcpa_flutter/presentation/widgets/stripe_card_input_form.dart';
import 'package:ukcpa_flutter/core/theme/app_theme.dart';

/// Test wrapper for StripeCardInputForm widget tests
class TestWrapper extends StatelessWidget {
  final Widget child;

  const TestWrapper({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }
}

void main() {
  group('StripeCardInputForm Widget Tests', () {
    testWidgets('should render card input form correctly', (WidgetTester tester) async {
      // Arrange
      bool cardChangedCalled = false;
      Map<String, dynamic>? receivedCardData;

      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (cardData) {
              cardChangedCalled = true;
              receivedCardData = cardData;
            },
            enabled: true,
          ),
        ),
      );

      // Assert - Check for key UI elements
      expect(find.text('Secure Payment'), findsOneWidget);
      expect(find.text('Your card details are encrypted and secure. We never store your full card number.'), findsOneWidget);
      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('should display error message when provided', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Please enter a valid card number';

      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (_) {},
            errorText: errorMessage,
          ),
        ),
      );

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should handle disabled state correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (_) {},
            enabled: false,
          ),
        ),
      );

      // Assert
      expect(find.byType(StripeCardInputForm), findsOneWidget);
      
      // Find the container with disabled styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StripeCardInputForm),
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, AppTheme.backgroundColor);
    });

    testWidgets('should display CardField widget', (WidgetTester tester) async {
      // Arrange
      bool cardChangedCalled = false;

      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (cardData) {
              cardChangedCalled = true;
            },
          ),
        ),
      );

      // Assert - Check that the CardField is present
      expect(find.byType(stripe.CardField), findsOneWidget);
    });

    testWidgets('should render with proper styling', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (_) {},
          ),
        ),
      );

      // Assert - Check for proper container styling
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StripeCardInputForm),
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(8.0));
      expect(decoration.color, Colors.white);
    });

    testWidgets('should apply error styling when errorText is provided', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (_) {},
            errorText: 'Invalid card number',
          ),
        ),
      );

      // Assert - Check for error border styling  
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StripeCardInputForm),
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.errorColor);
    });

    testWidgets('should display security notice with correct styling', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (_) {},
          ),
        ),
      );

      // Assert - Check security notice components
      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.text('Secure Payment'), findsOneWidget);
      expect(find.text('Your card details are encrypted and secure. We never store your full card number.'), findsOneWidget);

      // Check that security icon has success color
      final icon = tester.widget<Icon>(find.byIcon(Icons.security));
      expect(icon.color, AppTheme.successColor);
      expect(icon.size, 20);
    });

    testWidgets('should apply error styling when error is present', (WidgetTester tester) async {
      // Arrange
      const errorMessage = 'Card number is invalid';

      // Act
      await tester.pumpWidget(
        TestWrapper(
          child: StripeCardInputForm(
            onCardChanged: (_) {},
            errorText: errorMessage,
          ),
        ),
      );

      // Assert - Find error text with correct styling
      final errorText = tester.widget<Text>(find.text(errorMessage));
      expect(errorText.style?.color, AppTheme.errorColor);
      expect(errorText.style?.fontSize, 12);

      // Check that container has error border
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(StripeCardInputForm),
          matching: find.byType(Container),
        ).first,
      );
      
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, AppTheme.errorColor);
    });
  });

  group('CardValidationHelper Tests', () {
    test('should validate complete card correctly', () {
      // Arrange
      final completeCardData = {
        'complete': true,
        'validNumber': true,
        'validCVC': true,
        'validExpiryDate': true,
      };

      // Act
      final result = CardValidationHelper.validateCard(completeCardData);

      // Assert
      expect(result.isValid, true);
      expect(result.errorMessage, null);
      expect(result.cardData, completeCardData);
    });

    test('should return error for incomplete card', () {
      // Arrange
      final incompleteCardData = {
        'complete': false,
        'validNumber': false,
        'validCVC': false,
        'validExpiryDate': false,
      };

      // Act
      final result = CardValidationHelper.validateCard(incompleteCardData);

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage, 'Please complete all card fields');
      expect(result.cardData, null);
    });

    test('should return error for invalid card number', () {
      // Arrange
      final invalidNumberCardData = {
        'complete': true,
        'validNumber': false,
        'validCVC': true,
        'validExpiryDate': true,
      };

      // Act
      final result = CardValidationHelper.validateCard(invalidNumberCardData);

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage, 'Please enter a valid card number');
    });

    test('should return error for invalid expiry date', () {
      // Arrange
      final invalidExpiryCardData = {
        'complete': true,
        'validNumber': true,
        'validCVC': true,
        'validExpiryDate': false,
      };

      // Act
      final result = CardValidationHelper.validateCard(invalidExpiryCardData);

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage, 'Please enter a valid expiry date');
    });

    test('should return error for invalid CVC', () {
      // Arrange
      final invalidCVCCardData = {
        'complete': true,
        'validNumber': true,
        'validCVC': false,
        'validExpiryDate': true,
      };

      // Act
      final result = CardValidationHelper.validateCard(invalidCVCCardData);

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage, 'Please enter a valid security code');
    });

    test('should identify card brands correctly', () {
      // Test Visa
      expect(CardValidationHelper.getCardBrand('4242424242424242'), 'visa');
      
      // Test Mastercard
      expect(CardValidationHelper.getCardBrand('5555555555554444'), 'mastercard');
      
      // Test American Express
      expect(CardValidationHelper.getCardBrand('378282246310005'), 'amex');
      
      // Test Discover
      expect(CardValidationHelper.getCardBrand('6011111111111117'), 'discover');
      
      // Test unknown
      expect(CardValidationHelper.getCardBrand('1234567890123456'), 'unknown');
      expect(CardValidationHelper.getCardBrand(null), 'unknown');
      expect(CardValidationHelper.getCardBrand(''), 'unknown');
    });

    test('should format card number for display correctly', () {
      // Test valid card number
      expect(CardValidationHelper.formatCardNumber('4242424242424242'), '**** **** **** 4242');
      
      // Test short card number
      expect(CardValidationHelper.formatCardNumber('123'), '');
      
      // Test null/empty
      expect(CardValidationHelper.formatCardNumber(null), '');
      expect(CardValidationHelper.formatCardNumber(''), '');
    });
  });

  group('CardValidationResult Tests', () {
    test('should create valid result correctly', () {
      // Arrange
      final cardData = {'test': 'data'};

      // Act
      final result = CardValidationResult.valid(cardData);

      // Assert
      expect(result.isValid, true);
      expect(result.errorMessage, null);
      expect(result.cardData, cardData);
    });

    test('should create invalid result correctly', () {
      // Arrange
      const errorMessage = 'Invalid card';

      // Act
      final result = CardValidationResult.invalid(errorMessage);

      // Assert
      expect(result.isValid, false);
      expect(result.errorMessage, errorMessage);
      expect(result.cardData, null);
    });
  });
}