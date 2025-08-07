// Quick test to validate DisplayStatus fix
import 'package:ukcpa_flutter/domain/entities/course.dart';

void main() {
  // Test the fix - create a course with LIVE status
  final course = Course(
    id: '1',
    name: 'Test Course',
    price: 23370,
    active: true,
    displayStatus: DisplayStatus.live,
    fullyBooked: false,
    startDateTime: DateTime.now().add(Duration(days: 30)), // Future date
  );

  print('Course: ${course.name}');
  print('Display Status: ${course.displayStatus}');
  print('Is Available: ${course.isAvailable}');
  print('Active: ${course.active}');
  print('Fully Booked: ${course.fullyBooked}');
  
  if (course.isAvailable) {
    print('✅ SUCCESS: Course with LIVE status is now available!');
  } else {
    print('❌ FAILED: Course with LIVE status is not available');
  }
}