import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    String? profileImageUrl,
    String? phone,
    Address? address,
    String? stripeCustomerId,
    @Default([]) List<String> roles,
    DateTime? dateOfBirth,
    String? parentId,
    @Default([]) List<User> children,
  }) = _User;
  
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class Address with _$Address {
  const factory Address({
    String? line1,
    String? line2,
    String? city,
    String? county,
    String? country,
    String? postCode,
    String? name,
  }) = _Address;
  
  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
}