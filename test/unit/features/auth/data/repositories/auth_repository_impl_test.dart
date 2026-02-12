import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediconnect/core/error/exceptions.dart';
import 'package:mediconnect/core/error/failures.dart';
import 'package:mediconnect/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:mediconnect/features/auth/data/models/user_model.dart';
import 'package:mediconnect/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = UserModel(id: '1', email: tEmail);

  group('signInWithEmailAndPassword', () {
    test(
      'should return User when the call to remote data source is successful',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.signIn(any(), any()),
        ).thenAnswer((_) async => tUser);
        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );
        // assert
        verify(() => mockRemoteDataSource.signIn(tEmail, tPassword));
        expect(result, equals(const Right(tUser)));
      },
    );

    test(
      'should return ServerFailure when the call to remote data source throws ServerException',
      () async {
        // arrange
        when(
          () => mockRemoteDataSource.signIn(any(), any()),
        ).thenThrow(const ServerException('Server Error'));
        // act
        final result = await repository.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword,
        );
        // assert
        verify(() => mockRemoteDataSource.signIn(tEmail, tPassword));
        expect(result, equals(const Left(ServerFailure('Server Error'))));
      },
    );
  });
}
