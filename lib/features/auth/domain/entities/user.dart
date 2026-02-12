import 'package:equatable/equatable.dart';

enum UserRole { doctor, patient, unknown }

class User extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final String? photoUrl;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.role = UserRole.unknown,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [id, email, displayName, role, photoUrl];
}
