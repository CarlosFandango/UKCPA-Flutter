import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ukcpa_flutter/domain/entities/basket.dart';
import 'package:ukcpa_flutter/domain/entities/course.dart';
import 'package:ukcpa_flutter/presentation/providers/basket_provider.dart';

// Use centralized mocks for consistency
import '../../integration_test/mocks/mock_repositories.dart';
import '../../integration_test/mocks/mock_data_factory.dart';

void main() {
  late MockBasketRepository mockRepository;

  setUp(() {
    mockRepository = MockRepositoryFactory.getBasketRepository();
    MockConfig.configureForSpeed(); // Fast tests
  });

  /// Helper to create a widget with providers
  Widget createWidgetWithProviders(Widget child) {
    return ProviderScope(
      overrides: [
        basketRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('Basket State Display Widgets', () {
    testWidgets('should display empty basket state correctly', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getBasket()).thenAnswer((_) async => null);

      // Create a simple basket display widget
      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.basket == null || basketState.basket!.isEmpty) {
              return const Column(
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Your basket is empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some courses to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              );
            }
            
            return Text('Basket has ${basketState.basket!.itemCount} items');
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
      expect(find.text('Your basket is empty'), findsOneWidget);
      expect(find.text('Add some courses to get started'), findsOneWidget);
    });

    testWidgets('should display basket with items correctly', (WidgetTester tester) async {
      // Arrange - Use centralized mock data
      final basket = MockDataFactory.basketWithItems;
      // Note: MockBasketRepository already returns basketWithItems by default

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.basket == null || basketState.basket!.isEmpty) {
              return const Text('Empty basket');
            }
            
            final basket = basketState.basket!;
            return Column(
              children: [
                Text('${basket.itemCount} items in basket'),
                Text('Total: ${basket.formattedTotal}'),
                ...basket.items.map((item) => ListTile(
                  title: Text(item.course.name),
                  subtitle: Text(item.formattedTotalPrice),
                  trailing: IconButton(
                    key: Key('remove-${item.id}'),
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      // Remove item action
                    },
                  ),
                )),
              ],
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('1 items in basket'), findsOneWidget);
      expect(find.text('Total: £50.00'), findsOneWidget);
      expect(find.text('Test Course'), findsOneWidget);
      expect(find.text('£50.00'), findsOneWidget);
      expect(find.byKey(const Key('remove-1')), findsOneWidget);
    });

    testWidgets('should display loading state correctly', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getBasket()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return null;
      });

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.isLoading) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading basket...'),
                ],
              );
            }
            
            return const Text('Basket loaded');
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      
      // Assert loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading basket...'), findsOneWidget);
      
      // Wait for loading to complete
      await tester.pumpAndSettle();
      expect(find.text('Basket loaded'), findsOneWidget);
    });

    testWidgets('should display error state correctly', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getBasket()).thenThrow(const BasketException('Network error'));

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.hasError) {
              return Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading basket',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    basketState.error ?? 'Unknown error',
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(basketNotifierProvider.notifier).refreshBasket();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              );
            }
            
            return const Text('No error');
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading basket'), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Basket Item Interaction Widgets', () {
    testWidgets('should handle add to basket button interaction', (WidgetTester tester) async {
      // Arrange
      final mockCourse = Course(
        id: '1',
        name: 'Test Course',
        shortDescription: 'A test course',
        type: 'StudioCourse',
        price: 5000,
        displayStatus: DisplayStatus.live,
      );

      final emptyBasket = Basket(id: '1', items: [], total: 0);
      final basketWithItem = Basket(
        id: '1',
        items: [BasketItem(
          id: '1',
          course: mockCourse,
          price: 5000,
          totalPrice: 5000,
        )],
        total: 5000,
      );

      when(mockRepository.getBasket())
        .thenAnswer((_) async => emptyBasket);
      when(mockRepository.addItem('1', itemType: 'course'))
        .thenAnswer((_) async => BasketOperationResult(
          success: true,
          basket: basketWithItem,
          message: 'Course added',
        ));

      bool buttonPressed = false;
      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketNotifier = ref.watch(basketNotifierProvider.notifier);
            final isInBasket = ref.watch(courseInBasketProvider('1'));
            
            return ElevatedButton(
              key: const Key('add-to-basket-button'),
              onPressed: isInBasket ? null : () async {
                buttonPressed = true;
                await basketNotifier.addCourse('1');
              },
              child: Text(isInBasket ? 'In Basket' : 'Add to Basket'),
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Initially should show "Add to Basket"
      expect(find.text('Add to Basket'), findsOneWidget);
      expect(find.text('In Basket'), findsNothing);

      // Tap the button
      await tester.tap(find.byKey(const Key('add-to-basket-button')));
      await tester.pumpAndSettle();

      // Assert
      expect(buttonPressed, isTrue);
      verify(mockRepository.addItem('1', itemType: 'course')).called(1);
    });

    testWidgets('should handle remove from basket interaction', (WidgetTester tester) async {
      // Arrange
      final mockCourse = Course(
        id: '1',
        name: 'Test Course',
        shortDescription: 'A test course',
        type: 'StudioCourse',
        price: 5000,
        displayStatus: DisplayStatus.live,
      );

      final basketItem = BasketItem(
        id: '1',
        course: mockCourse,
        price: 5000,
        totalPrice: 5000,
      );

      final basketWithItem = Basket(
        id: '1',
        items: [basketItem],
        total: 5000,
      );

      final emptyBasket = Basket(id: '1', items: [], total: 0);

      when(mockRepository.getBasket()).thenAnswer((_) async => basketWithItem);
      when(mockRepository.removeItem('1', 'course'))
        .thenAnswer((_) async => BasketOperationResult(
          success: true,
          basket: emptyBasket,
          message: 'Item removed',
        ));

      bool removePressed = false;
      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketNotifier = ref.watch(basketNotifierProvider.notifier);
            
            return ElevatedButton(
              key: const Key('remove-from-basket-button'),
              onPressed: () async {
                removePressed = true;
                await basketNotifier.removeCourse('1');
              },
              child: const Text('Remove from Basket'),
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('remove-from-basket-button')));
      await tester.pumpAndSettle();

      // Assert
      expect(removePressed, isTrue);
      verify(mockRepository.removeItem('1', 'course')).called(1);
    });
  });

  group('Basket Summary Widgets', () {
    testWidgets('should display basket totals correctly', (WidgetTester tester) async {
      // Arrange
      final basket = Basket(
        id: '1',
        subTotal: 10000, // £100.00
        discountTotal: 1000, // £10.00 discount
        promoCodeDiscountValue: 500, // £5.00 promo discount
        creditTotal: 200, // £2.00 credit applied
        total: 8300, // £83.00 final total
        chargeTotal: 8300,
      );

      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.basket == null) {
              return const Text('No basket');
            }
            
            final basket = basketState.basket!;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text(basket.formattedSubTotal),
                  ],
                ),
                if (basket.hasDiscounts) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discounts:'),
                      Text('-${basket.formattedSavings}', 
                        style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                ],
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(basket.formattedTotal,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Subtotal:'), findsOneWidget);
      expect(find.text('£100.00'), findsOneWidget);
      expect(find.text('Discounts:'), findsOneWidget);
      expect(find.text('-£17.00'), findsOneWidget); // Total savings
      expect(find.text('Total:'), findsOneWidget);
      expect(find.text('£83.00'), findsOneWidget);
    });

    testWidgets('should display basket item count badge', (WidgetTester tester) async {
      // Arrange
      final basket = Basket(
        id: '1',
        items: List.generate(3, (index) => BasketItem(
          id: '$index',
          course: Course(
            id: '$index',
            name: 'Course $index',
            shortDescription: 'Test course $index',
            type: 'StudioCourse',
            price: 5000,
            displayStatus: DisplayStatus.live,
          ),
          price: 5000,
          totalPrice: 5000,
        )),
        total: 15000,
      );

      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final itemCount = ref.watch(basketItemCountProvider);
            
            return Stack(
              children: [
                const Icon(Icons.shopping_basket, size: 32),
                if (itemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$itemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.shopping_basket), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      
      // Verify badge styling
      final badgeContainer = tester.widget<Container>(
        find.ancestor(of: find.text('3'), matching: find.byType(Container))
      );
      expect((badgeContainer.decoration as BoxDecoration).color, Colors.red);
      expect((badgeContainer.decoration as BoxDecoration).shape, BoxShape.circle);
    });
  });

  group('Basket Form Widgets', () {
    testWidgets('should handle promo code form interaction', (WidgetTester tester) async {
      // Arrange
      final basket = Basket(id: '1', total: 5000);
      
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);
      when(mockRepository.applyPromoCode('TESTCODE'))
        .thenAnswer((_) async => BasketOperationResult(
          success: true,
          basket: basket.copyWith(
            promoCodeDiscountValue: 500,
            total: 4500,
          ),
          message: 'Promo code applied',
        ));

      String enteredCode = '';
      bool formSubmitted = false;

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketNotifier = ref.watch(basketNotifierProvider.notifier);
            
            return Column(
              children: [
                TextFormField(
                  key: const Key('promo-code-field'),
                  decoration: const InputDecoration(
                    labelText: 'Promo Code',
                    hintText: 'Enter promo code',
                  ),
                  onChanged: (value) => enteredCode = value,
                ),
                ElevatedButton(
                  key: const Key('apply-promo-button'),
                  onPressed: () async {
                    if (enteredCode.isNotEmpty) {
                      formSubmitted = true;
                      await basketNotifier.applyPromoCode(enteredCode);
                    }
                  },
                  child: const Text('Apply Code'),
                ),
              ],
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Enter promo code
      await tester.enterText(find.byKey(const Key('promo-code-field')), 'TESTCODE');
      await tester.pump();

      // Tap apply button
      await tester.tap(find.byKey(const Key('apply-promo-button')));
      await tester.pumpAndSettle();

      // Assert
      expect(enteredCode, 'TESTCODE');
      expect(formSubmitted, isTrue);
      verify(mockRepository.applyPromoCode('TESTCODE')).called(1);
    });

    testWidgets('should handle credit usage toggle', (WidgetTester tester) async {
      // Arrange
      final basket = Basket(id: '1', total: 5000);
      
      when(mockRepository.getBasket()).thenAnswer((_) async => basket);
      when(mockRepository.useCreditForBasket(true))
        .thenAnswer((_) async => BasketOperationResult(
          success: true,
          basket: basket.copyWith(
            creditTotal: 200,
            total: 4800,
          ),
          message: 'Credit applied',
        ));

      bool creditToggled = false;

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketNotifier = ref.watch(basketNotifierProvider.notifier);
            
            return SwitchListTile(
              key: const Key('credit-toggle'),
              title: const Text('Use Available Credits'),
              subtitle: const Text('Apply £2.00 credit to this order'),
              value: false,
              onChanged: (bool value) async {
                creditToggled = true;
                await basketNotifier.toggleCreditUsage(value);
              },
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Tap the toggle
      await tester.tap(find.byKey(const Key('credit-toggle')));
      await tester.pumpAndSettle();

      // Assert
      expect(creditToggled, isTrue);
      verify(mockRepository.useCreditForBasket(true)).called(1);
    });
  });

  group('Basket Navigation Widgets', () {
    testWidgets('should display checkout button when basket has items', (WidgetTester tester) async {
      // Arrange
      final basket = Basket(
        id: '1',
        items: [BasketItem(
          id: '1',
          course: Course(
            id: '1',
            name: 'Test Course',
            shortDescription: 'A test course',
            type: 'StudioCourse',
            price: 5000,
            displayStatus: DisplayStatus.live,
          ),
          price: 5000,
          totalPrice: 5000,
        )],
        total: 5000,
      );

      when(mockRepository.getBasket()).thenAnswer((_) async => basket);

      bool checkoutPressed = false;

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.basket?.isEmpty ?? true) {
              return const SizedBox.shrink();
            }
            
            return ElevatedButton(
              key: const Key('checkout-button'),
              onPressed: () {
                checkoutPressed = true;
                // Navigate to checkout
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.blue,
              ),
              child: Text(
                'Checkout - ${basketState.basket!.formattedTotal}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('checkout-button')), findsOneWidget);
      expect(find.text('Checkout - £50.00'), findsOneWidget);

      // Test button interaction
      await tester.tap(find.byKey(const Key('checkout-button')));
      await tester.pump();

      expect(checkoutPressed, isTrue);
    });

    testWidgets('should not display checkout button for empty basket', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getBasket()).thenAnswer((_) async => null);

      final widget = createWidgetWithProviders(
        Consumer(
          builder: (context, ref, child) {
            final basketState = ref.watch(basketNotifierProvider);
            
            if (basketState.basket?.isEmpty ?? true) {
              return const SizedBox.shrink();
            }
            
            return ElevatedButton(
              key: const Key('checkout-button'),
              onPressed: () {},
              child: const Text('Checkout'),
            );
          },
        ),
      );

      // Act
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const Key('checkout-button')), findsNothing);
    });
  });
}