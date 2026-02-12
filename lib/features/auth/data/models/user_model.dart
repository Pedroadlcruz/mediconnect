import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.role,
    super.photoUrl,
  });

  factory UserModel.fromFirebaseUser(firebase.User user, {UserRole? role}) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      role: role ?? UserRole.unknown,
    );
  }

  // Also could map role from Custom Claims if available
}
