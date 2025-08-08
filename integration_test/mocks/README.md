# Centralized Mock System for Integration Tests

This directory contains the centralized mock system for UKCPA Flutter integration tests. When GraphQL schemas or API responses change, update the files in this directory to maintain consistency across all tests.

## 🎯 Key Benefits

- **Single source of truth** for all mock data
- **Consistent responses** across all integration tests  
- **Easy maintenance** when GraphQL schemas change
- **Flexible configuration** for different test scenarios
- **Type-safe mock data** matching real entities
- **193 passing tests** with centralized mock system
- **Resolved Course/StudioCourse/OnlineCourse type conflicts** using proper GraphQL union handling
- **Fixed DisplayStatus enum alignment** with backend (DRAFT/PREVIEW/LIVE)

## 📁 File Structure

### `mock_data_factory.dart`
- **Purpose**: Central factory for creating consistent mock data
- **Contains**: Mock users, terms, course groups, sessions, and responses
- **Update when**: GraphQL schema changes, new entities added, or response formats change

### `mock_repositories.dart`
- **Purpose**: Mock implementations of all repositories using the data factory
- **Contains**: MockAuthRepository, MockTermsRepository, MockBasketRepository, MockCourseRepository, and factory methods
- **Features**: Full CourseRepository implementation with union type handling, proper inheritance support
- **Update when**: Repository interfaces change or new repositories are added

### `README.md` (this file)
- **Purpose**: Documentation and usage guidelines
- **Update when**: New patterns or configurations are added

## 🚀 Quick Start

### Basic Usage (Unit Tests)

```dart
import '../../integration_test/mocks/mock_repositories.dart';
import '../../integration_test/mocks/mock_data_factory.dart';

void main() {
  late MockCourseRepository mockRepository;
  
  setUp(() {
    mockRepository = MockRepositoryFactory.getCourseRepository();
    MockConfig.configureForSpeed(); // Ultra-fast mode
  });
  
  test('should return courses', () async {
    final result = await mockRepository.getCourses();
    expect(result.courses, hasLength(2)); // Studio + Online course
  });
}
```

### Integration Test Usage

```dart
// Use in integration test
testWidgets('My test', (tester) async {
  await MockedFastTestManager.initializeMocked(tester);
  
  // Test uses centralized mocks automatically
  expect(find.text('Ballet Beginners'), findsOneWidget);
});
```

### Ultra-Fast Testing

```dart
// No delays, instant responses
await MockedFastTestManager.initializeUltraFast(tester);
```

### Error Scenario Testing

```dart
// Simulate network and server errors
await MockedFastTestManager.initializeWithErrors(tester);
```

### Empty State Testing

```dart
// Return empty data sets
await MockedFastTestManager.initializeEmpty(tester);
```

## 🔧 Configuration Options

### Speed Configuration
```dart
MockRepositoryFactory.configureForSpeed(); // No delays
MockRepositoryFactory.resetToDefaults();   // Normal delays
```

### Error Simulation
```dart
MockConfig.simulateNetworkErrors = true;  // Throw network errors
MockConfig.simulateServerErrors = true;   // Throw server errors
MockConfig.returnEmptyData = true;        // Return empty results
```

### Custom Mock Data
```dart
// Create custom user
final user = MockDataFactory.createTestUser(
  email: 'custom@test.com',
  firstName: 'Custom',
  lastName: 'User',
);

// Create custom course group
final courseGroup = MockDataFactory.createCourseGroup(
  name: 'Custom Dance Class',
  price: 60.0,
  level: 'Advanced',
);
```

## 📊 Standard Mock Data

### Test User
- **Email**: `test@ukcpa.com`
- **Password**: `testpassword`
- **Name**: Test User
- **ID**: 123

### Course Groups
1. **Ballet Beginners** - £45, Beginner, Adult
2. **Jazz Intermediate** - £50, Intermediate, Teen  
3. **Contemporary Advanced** - £55, Advanced, Adult
4. **Hip Hop Kids** - £40, Beginner, Child
5. **Tap Dancing All Levels** - £48, All Levels, All Ages

### Terms
- **Spring Term 2024** - Current + 90 days, 5 course groups
- **Summer Term 2024** - +91 to +181 days, 3 course groups

## 🛠️ Maintenance Guide

### When GraphQL Schema Changes

1. **Update MockDataFactory**:
   ```dart
   // Add new fields to entity creation methods
   static CourseGroup createCourseGroup({
     // ... existing fields
     String? newField,  // Add new field
   }) {
     return CourseGroup(
       // ... existing fields
       newField: newField ?? 'default value',
     );
   }
   ```

2. **Update Standard Data**:
   ```dart
   // Update createStandardCourseGroups() to include new field
   createCourseGroup(
     name: 'Ballet Beginners',
     newField: 'some value',  // Add new field
   ),
   ```

3. **Run Tests**: All tests using centralized mocks will automatically use new data structure

### When Adding New Repository

1. **Create Mock Repository**:
   ```dart
   class MockNewRepository extends Mock implements NewRepository {
     @override
     Future<SomeEntity> getData() async {
       if (MockConfig.enableDelays) {
         await Future.delayed(MockDataFactory.dataLoadDelay);
       }
       return MockDataFactory.createSomeEntity();
     }
   }
   ```

2. **Add to Factory**:
   ```dart
   static MockNewRepository getNewRepository() {
     return _newRepository ??= MockNewRepository();
   }
   ```

3. **Update Test Manager**:
   ```dart
   overrides: [
     // ... existing overrides
     newRepositoryProvider.overrideWithValue(MockRepositoryFactory.getNewRepository()),
   ],
   ```

### When Adding New Mock Data

1. **Add to MockDataFactory**:
   ```dart
   static SomeEntity createSomeEntity({
     String? field1,
     int? field2,
   }) {
     return SomeEntity(
       field1: field1 ?? 'default',
       field2: field2 ?? 123,
     );
   }
   
   static List<SomeEntity> createStandardSomeEntities() {
     return [
       createSomeEntity(field1: 'value1'),
       createSomeEntity(field1: 'value2'),
     ];
   }
   ```

2. **Use in Repository Mock**:
   ```dart
   @override
   Future<List<SomeEntity>> getSomeEntities() async {
     return MockDataFactory.createStandardSomeEntities();
   }
   ```

## 🧪 Testing Different Scenarios

### Valid Login Flow
```dart
// Uses MockDataFactory.defaultTestEmail/defaultTestPassword
await MockedFastTestManager.initializeMocked(tester);
```

### Invalid Login Flow  
```dart
// Use different credentials
await tester.enterText(find.byKey(Key('email')), 'wrong@test.com');
// MockAuthRepository will return error response
```

### Network Error Testing
```dart
await MockedFastTestManager.initializeWithErrors(tester);
// All repository calls will throw network errors
```

### Empty State Testing
```dart
await MockedFastTestManager.initializeEmpty(tester);  
// Repositories return empty lists/null values
```

### Custom Configuration
```dart
MockConfig.enableDelays = false;        // Ultra-fast
MockConfig.simulateNetworkErrors = true; // With errors
await MockedFastTestManager.initializeMocked(tester);
```

## 🔄 Migration from Old Mocks

### Before (Scattered Mocks)
```dart
// Different mock data in each test file
class MyMockAuthRepo {
  Future<User> getCurrentUser() => User(id: '1', email: 'test1@test.com');
}

class AnotherMockAuthRepo {
  Future<User> getCurrentUser() => User(id: '2', email: 'test2@test.com');
}
```

### After (Centralized Mocks)
```dart
// All tests use same centralized mock
await MockedFastTestManager.initializeMocked(tester);
// Automatically gets MockDataFactory.createTestUser() everywhere
```

## ⚠️ Important Notes

1. **Always use MockDataFactory** for creating mock data
2. **Don't hardcode mock data** in individual tests
3. **Update centralized mocks** when schemas change
4. **Use configuration methods** for different test scenarios
5. **Reset configuration** between test suites if needed

## 📈 Performance Impact

- **Before**: Each test created its own mocks (~200ms setup)
- **After**: Shared mock instances (~50ms setup)
- **Ultra-fast mode**: No delays (~10ms responses)
- **Standard mode**: Realistic delays (~100ms responses)

This centralized system ensures consistency while maintaining the speed benefits of mocked integration tests.

## 🔧 Architecture & Type System

### GraphQL Union Types in Flutter

The backend uses inheritance (`StudioCourse extends Course`) while Flutter uses separate Freezed classes with GraphQL union handling:

**Backend (TypeScript)**:
```typescript
@Entity()
export class Course extends BaseEntity { ... }

@ChildEntity() 
export class StudioCourse extends Course { ... }

@ChildEntity()
export class OnlineCourse extends Course { ... }
```

**Frontend (Dart/Flutter)**:
```dart
@freezed
class Course with _$Course { ... }

@freezed  
class StudioCourse with _$StudioCourse { ... } // Separate class

@freezed
class OnlineCourse with _$OnlineCourse { ... } // Separate class
```

### Mock Repository Type Handling

To properly handle this difference, the mock repositories return base `Course` objects:

```dart
@override
Future<List<Course>> getCourses() async {
  // Return base Course objects, not subclasses
  return <Course>[
    MockDataFactory.createCourse(type: 'StudioCourse'),
    MockDataFactory.createCourse(type: 'OnlineCourse'),
  ];
}
```

### DisplayStatus Enum Alignment

Ensure Flutter enum values match backend exactly:

**Backend**: `DRAFT`, `PREVIEW`, `LIVE`  
**Flutter**: `DisplayStatus.draft`, `DisplayStatus.preview`, `DisplayStatus.live`

❌ **Don't use**: `DisplayStatus.published` (doesn't exist in backend)  
✅ **Use**: `DisplayStatus.live` for published courses

## 🚨 Common Issues & Solutions

### Issue: Type 'StudioCourse' cannot be assigned to type 'Course'

**Solution**: Use `MockDataFactory.createCourse()` instead of specific subclasses in repository methods.

### Issue: DisplayStatus.published not found

**Solution**: Replace with `DisplayStatus.live` - the backend only has DRAFT/PREVIEW/LIVE.

### Issue: Address import conflicts

**Solution**: Use `import 'package:ukcpa_flutter/domain/entities/user.dart' hide Address;` to avoid conflicts.

## 📸 Screenshot Integration

The centralized mock system works seamlessly with screenshot capture for UX validation.

**📖 See**: `@integration_test/SCREENSHOT_GUIDE.md` for complete documentation.

**Quick Reference**:
```bash
# Run mocked tests with screenshots
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/flows/course_group_ux_review_test.dart -d emulator-5554
```

Screenshots show UI populated with consistent mock data, enabling reliable visual validation of UX issues.