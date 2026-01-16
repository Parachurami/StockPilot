import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_urls.dart';
import '../../core/error/failures.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;

  AuthRepository(this._apiService);

  Future<Either<Failure, User>> login(String username, String password) async {
    try {
      final response = await _apiService.dio.post(
        ApiUrls.login,
        data: {'username': username, 'password': password},
      );

      // DummyJSON returns the user object directly with the token
      return Right(User.fromJson(response.data));
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response!.statusCode == 400 || e.response!.statusCode == 401) {
          return const Left(ServerFailure('Invalid username or password.'));
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError) {
        return const Left(
          ServerFailure('Please check your internet connection.'),
        );
      }
      return const Left(
        ServerFailure('Something went wrong. Please try again.'),
      );
    } catch (e) {
      return const Left(ServerFailure('An unexpected error occurred.'));
    }
  }
}
