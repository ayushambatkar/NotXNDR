import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({required super.code, required super.fcmToken});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      code: map['code'] as String,
      fcmToken: map['fcmToken'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'code': code, 'fcmToken': fcmToken};
  }
}
