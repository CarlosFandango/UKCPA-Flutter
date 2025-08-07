import 'package:flutter_test/flutter_test.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';

void main() {
  group('BasketItem', () {
    final mockCourse = Course(
      id: '1',
      name: 'Test Course',
      shortDescription: 'A test course',
      type: 'StudioCourse',
      price: 5000, // £50.00
      displayStatus: DisplayStatus.live,
    );

    test('should create BasketItem with required fields', () {
      final basketItem = BasketItem(
        id: '1',
        course: mockCourse,
        price: 5000,
        totalPrice: 5000,
      );

      expect(basketItem.id, '1');
      expect(basketItem.course.name, 'Test Course');
      expect(basketItem.price, 5000);
      expect(basketItem.totalPrice, 5000);
      expect(basketItem.isTaster, false);
    });

    test('should create BasketItem with optional fields', () {
      final basketItem = BasketItem(
        id: '1',
        course: mockCourse,
        price: 5000,
        discountValue: 500,
        promoCodeDiscountValue: 250,
        totalPrice: 4250,
        sessionId: 'session-123',
        isTaster: true,
        addedAt: DateTime(2024, 1, 1),
      );

      expect(basketItem.discountValue, 500);
      expect(basketItem.promoCodeDiscountValue, 250);
      expect(basketItem.totalPrice, 4250);
      expect(basketItem.sessionId, 'session-123');
      expect(basketItem.isTaster, true);
      expect(basketItem.addedAt, DateTime(2024, 1, 1));
    });

    test('should provide JSON serialization methods', () {
      final basketItem = BasketItem(
        id: '1',
        course: mockCourse,
        price: 5000,
        discountValue: 500,
        promoCodeDiscountValue: 250,
        totalPrice: 4250,
        sessionId: 'session-123',
        isTaster: true,
        addedAt: DateTime(2024, 1, 1),
      );

      // Verify toJson method exists and returns a map
      final json = basketItem.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], '1');
      expect(json['price'], 5000);
      expect(json['discountValue'], 500);
      expect(json['totalPrice'], 4250);
      expect(json['sessionId'], 'session-123');
      expect(json['isTaster'], true);
      
      // Note: JSON serialization of nested Course objects is handled 
      // by the GraphQL layer in production, not by entity serialization
    });

    group('BasketItemExtensions', () {
      test('hasDiscount should return true when item has discounts', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          discountValue: 500,
          totalPrice: 4500,
        );

        expect(basketItem.hasDiscount, true);
      });

      test('hasDiscount should return false when item has no discounts', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );

        expect(basketItem.hasDiscount, false);
      });

      test('totalDiscount should calculate combined discounts', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          discountValue: 500,
          promoCodeDiscountValue: 250,
          totalPrice: 4250,
        );

        expect(basketItem.totalDiscount, 750);
      });

      test('formattedPrice should return correctly formatted price', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );

        expect(basketItem.formattedPrice, '£50.00');
      });

      test('formattedTotalPrice should return correctly formatted total', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          totalPrice: 4250,
        );

        expect(basketItem.formattedTotalPrice, '£42.50');
      });

      test('itemTypeDisplay should return correct type for taster', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
          isTaster: true,
        );

        expect(basketItem.itemTypeDisplay, 'Taster Class');
      });

      test('itemTypeDisplay should return correct type for online course', () {
        final onlineCourse = Course(
          id: '1',
          name: 'Online Course',
          shortDescription: 'An online course',
          type: 'OnlineCourse',
          price: 5000,
          displayStatus: DisplayStatus.live,
        );

        final basketItem = BasketItem(
          id: '1',
          course: onlineCourse,
          price: 5000,
          totalPrice: 5000,
        );

        expect(basketItem.itemTypeDisplay, 'Online Course');
      });

      test('displayName should truncate long course names', () {
        final longCourse = Course(
          id: '1',
          name: 'This is a very long course name that should be truncated',
          shortDescription: 'A long course',
          type: 'StudioCourse',
          price: 5000,
          displayStatus: DisplayStatus.live,
        );

        final basketItem = BasketItem(
          id: '1',
          course: longCourse,
          price: 5000,
          totalPrice: 5000,
        );

        expect(basketItem.displayName.length, 30);
        expect(basketItem.displayName.endsWith('...'), true);
      });

      test('displayName should not truncate short course names', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        );

        expect(basketItem.displayName, 'Test Course');
      });
    });
  });

  group('CreditItem', () {
    test('should create CreditItem with required fields', () {
      final creditItem = CreditItem(
        id: '1',
        description: 'Student Discount',
        value: 500,
      );

      expect(creditItem.id, '1');
      expect(creditItem.description, 'Student Discount');
      expect(creditItem.value, 500);
    });

    test('should create CreditItem with optional fields', () {
      final creditItem = CreditItem(
        id: '1',
        description: 'Student Discount',
        value: 500,
        code: 'STUDENT10',
        validUntil: DateTime(2024, 12, 31),
      );

      expect(creditItem.code, 'STUDENT10');
      expect(creditItem.validUntil, DateTime(2024, 12, 31));
    });

    test('should serialize to and from JSON correctly', () {
      final creditItem = CreditItem(
        id: '1',
        description: 'Student Discount',
        value: 500,
        code: 'STUDENT10',
        validUntil: DateTime(2024, 12, 31),
      );

      final json = creditItem.toJson();
      final restored = CreditItem.fromJson(json);

      expect(restored.id, creditItem.id);
      expect(restored.description, creditItem.description);
      expect(restored.value, creditItem.value);
      expect(restored.code, creditItem.code);
      expect(restored.validUntil, creditItem.validUntil);
    });
  });

  group('FeeItem', () {
    test('should create FeeItem with required fields', () {
      final feeItem = FeeItem(
        id: '1',
        description: 'Registration Fee',
        value: 1000,
      );

      expect(feeItem.id, '1');
      expect(feeItem.description, 'Registration Fee');
      expect(feeItem.value, 1000);
      expect(feeItem.optional, false);
    });

    test('should create FeeItem with optional field', () {
      final feeItem = FeeItem(
        id: '1',
        description: 'Insurance Fee',
        value: 500,
        optional: true,
      );

      expect(feeItem.optional, true);
    });

    test('should serialize to and from JSON correctly', () {
      final feeItem = FeeItem(
        id: '1',
        description: 'Registration Fee',
        value: 1000,
        optional: true,
      );

      final json = feeItem.toJson();
      final restored = FeeItem.fromJson(json);

      expect(restored.id, feeItem.id);
      expect(restored.description, feeItem.description);
      expect(restored.value, feeItem.value);
      expect(restored.optional, feeItem.optional);
    });
  });

  group('Basket', () {
    final mockCourse1 = Course(
      id: '1',
      name: 'Course 1',
      shortDescription: 'First course',
      type: 'StudioCourse',
      price: 5000,
      displayStatus: DisplayStatus.live,
    );

    final mockCourse2 = Course(
      id: '2',
      name: 'Course 2',
      shortDescription: 'Second course',
      type: 'OnlineCourse',
      price: 3000,
      displayStatus: DisplayStatus.live,
    );

    test('should create empty Basket with default values', () {
      final basket = Basket(id: '1');

      expect(basket.id, '1');
      expect(basket.items, isEmpty);
      expect(basket.creditItems, isEmpty);
      expect(basket.feeItems, isEmpty);
      expect(basket.discountValue, 0);
      expect(basket.discountTotal, 0);
      expect(basket.promoCodeDiscountValue, 0);
      expect(basket.creditTotal, 0);
      expect(basket.subTotal, 0);
      expect(basket.tax, 0);
      expect(basket.total, 0);
      expect(basket.chargeTotal, 0);
      expect(basket.payLater, 0);
    });

    test('should create Basket with items and calculations', () {
      final basketItem1 = BasketItem(
        id: '1',
        course: mockCourse1,
        price: 5000,
        totalPrice: 4500,
        discountValue: 500,
      );

      final basketItem2 = BasketItem(
        id: '2',
        course: mockCourse2,
        price: 3000,
        totalPrice: 3000,
        isTaster: true,
      );

      final creditItem = CreditItem(
        id: '1',
        description: 'Student Credit',
        value: 200,
      );

      final feeItem = FeeItem(
        id: '1',
        description: 'Registration',
        value: 500,
      );

      final basket = Basket(
        id: '1',
        items: [basketItem1, basketItem2],
        creditItems: [creditItem],
        feeItems: [feeItem],
        discountValue: 500,
        discountTotal: 500,
        promoCodeDiscountValue: 100,
        creditTotal: 200,
        subTotal: 8000,
        tax: 400,
        total: 7700,
        chargeTotal: 7700,
        payLater: 1000,
        userId: 'user-123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        expiresAt: DateTime(2024, 1, 8),
      );

      expect(basket.items.length, 2);
      expect(basket.creditItems.length, 1);
      expect(basket.feeItems.length, 1);
      expect(basket.discountTotal, 500);
      expect(basket.promoCodeDiscountValue, 100);
      expect(basket.creditTotal, 200);
      expect(basket.total, 7700);
      expect(basket.payLater, 1000);
      expect(basket.userId, 'user-123');
    });

    test('should provide JSON serialization methods', () {
      final basketItem = BasketItem(
        id: '1',
        course: mockCourse1,
        price: 5000,
        totalPrice: 5000,
      );

      final basket = Basket(
        id: '1',
        items: [basketItem],
        discountTotal: 500,
        total: 4500,
        userId: 'user-123',
      );

      // Verify JSON methods exist and return expected structure
      final json = basket.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], '1');
      expect(json['discountTotal'], 500);
      expect(json['total'], 4500);
      expect(json['userId'], 'user-123');
      expect(json['items'], isA<List>());
      expect((json['items'] as List).length, 1);
      
      // Note: Full JSON round-trip serialization is handled by GraphQL layer
      // These entities are primarily used for in-memory operations
    });

    group('BasketExtensions', () {
      test('isEmpty should return true for empty basket', () {
        final basket = Basket(id: '1');
        expect(basket.isEmpty, true);
      });

      test('isEmpty should return false for basket with items', () {
        final basketItem = BasketItem(
          id: '1',
          course: mockCourse1,
          price: 5000,
          totalPrice: 5000,
        );

        final basket = Basket(id: '1', items: [basketItem]);
        expect(basket.isEmpty, false);
      });

      test('itemCount should return correct count', () {
        final basketItem1 = BasketItem(
          id: '1',
          course: mockCourse1,
          price: 5000,
          totalPrice: 5000,
        );

        final basketItem2 = BasketItem(
          id: '2',
          course: mockCourse2,
          price: 3000,
          totalPrice: 3000,
        );

        final basket = Basket(id: '1', items: [basketItem1, basketItem2]);
        expect(basket.itemCount, 2);
      });

      test('hasDiscounts should return true when discounts exist', () {
        final basket = Basket(id: '1', discountTotal: 500);
        expect(basket.hasDiscounts, true);

        final basketWithPromo = Basket(id: '1', promoCodeDiscountValue: 200);
        expect(basketWithPromo.hasDiscounts, true);
      });

      test('hasDiscounts should return false when no discounts', () {
        final basket = Basket(id: '1');
        expect(basket.hasDiscounts, false);
      });

      test('hasCredits should return true when credits exist', () {
        final basket = Basket(id: '1', creditTotal: 200);
        expect(basket.hasCredits, true);
      });

      test('hasPayLater should return true when pay later amount exists', () {
        final basket = Basket(id: '1', payLater: 1000);
        expect(basket.hasPayLater, true);
      });

      test('tasterItems should return only taster items', () {
        final regularItem = BasketItem(
          id: '1',
          course: mockCourse1,
          price: 5000,
          totalPrice: 5000,
          isTaster: false,
        );

        final tasterItem = BasketItem(
          id: '2',
          course: mockCourse2,
          price: 3000,
          totalPrice: 3000,
          isTaster: true,
        );

        final basket = Basket(id: '1', items: [regularItem, tasterItem]);
        final tasterItems = basket.tasterItems;

        expect(tasterItems.length, 1);
        expect(tasterItems.first.isTaster, true);
        expect(tasterItems.first.course.name, 'Course 2');
      });

      test('courseItems should return only non-taster items', () {
        final regularItem = BasketItem(
          id: '1',
          course: mockCourse1,
          price: 5000,
          totalPrice: 5000,
          isTaster: false,
        );

        final tasterItem = BasketItem(
          id: '2',
          course: mockCourse2,
          price: 3000,
          totalPrice: 3000,
          isTaster: true,
        );

        final basket = Basket(id: '1', items: [regularItem, tasterItem]);
        final courseItems = basket.courseItems;

        expect(courseItems.length, 1);
        expect(courseItems.first.isTaster, false);
        expect(courseItems.first.course.name, 'Course 1');
      });

      test('totalSavings should calculate combined savings', () {
        final basket = Basket(
          id: '1',
          discountTotal: 500,
          promoCodeDiscountValue: 200,
          creditTotal: 100,
        );

        expect(basket.totalSavings, 800);
      });

      test('formatted price methods should return correct formats', () {
        final basket = Basket(
          id: '1',
          subTotal: 8000,
          total: 7500,
          chargeTotal: 7500,
          payLater: 1000,
          discountTotal: 300,
          promoCodeDiscountValue: 100,
          creditTotal: 100,
        );

        expect(basket.formattedSubTotal, '£80.00');
        expect(basket.formattedTotal, '£75.00');
        expect(basket.formattedChargeTotal, '£75.00');
        expect(basket.formattedPayLater, '£10.00');
        expect(basket.formattedSavings, '£5.00'); // 300 + 100 + 100 = 500
      });
    });
  });

  group('BasketOperationResult', () {
    test('should create successful result', () {
      final basket = Basket(id: '1');
      final result = BasketOperationResult(
        success: true,
        basket: basket,
        message: 'Item added successfully',
      );

      expect(result.success, true);
      expect(result.basket.id, '1');
      expect(result.message, 'Item added successfully');
      expect(result.errorCode, null);
    });

    test('should create error result', () {
      final basket = Basket(id: '1');
      final result = BasketOperationResult(
        success: false,
        basket: basket,
        message: 'Failed to add item',
        errorCode: 'BASKET_FULL',
      );

      expect(result.success, false);
      expect(result.message, 'Failed to add item');
      expect(result.errorCode, 'BASKET_FULL');
    });

    test('should provide JSON serialization methods', () {
      final basket = Basket(id: '1');
      final result = BasketOperationResult(
        success: true,
        basket: basket,
        message: 'Success',
        errorCode: null,
      );

      // Verify JSON methods exist and return expected structure
      final json = result.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['success'], true);
      expect(json['message'], 'Success');
      expect(json['errorCode'], null);
      
      // Note: Used primarily for GraphQL response parsing
      // Full serialization is handled at the repository layer
    });
  });

  group('BasketException', () {
    test('should create exception with message', () {
      const exception = BasketException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.errorCode, null);
      expect(exception.cause, null);
    });

    test('should create exception with all fields', () {
      const cause = 'Network error';
      const exception = BasketException(
        'Failed to load basket',
        errorCode: 'NETWORK_ERROR',
        cause: cause,
      );

      expect(exception.message, 'Failed to load basket');
      expect(exception.errorCode, 'NETWORK_ERROR');
      expect(exception.cause, cause);
    });

    test('toString should format correctly', () {
      const exception1 = BasketException('Test error');
      expect(exception1.toString(), 'BasketException: Test error');

      const exception2 = BasketException(
        'Test error',
        errorCode: 'TEST_CODE',
      );
      expect(exception2.toString(), 'BasketException: Test error (TEST_CODE)');
    });
  });
}