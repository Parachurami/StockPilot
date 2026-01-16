import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:stock_pilot/core/constants/api_urls.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/data/models/product_model.dart';
import 'package:stock_pilot/data/repositories/product_repository.dart';
import 'package:stock_pilot/data/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate MockApiService
@GenerateMocks([ApiService, Dio])
import 'product_repository_test.mocks.dart';

void main() {
  late ProductRepository repository;
  late MockApiService mockApiService;
  late MockDio mockDio;

  setUp(() {
    mockApiService = MockApiService();
    mockDio = MockDio();
    when(mockApiService.dio).thenReturn(mockDio);
    repository = ProductRepository(mockApiService);

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  group('getProducts', () {
    test(
      'should return list of products when API call is successful',
      () async {
        // Arrange
        final mockResponse = {
          'products': [
            {
              'id': 1,
              'title': 'Test Product',
              'description': 'Description',
              'price': 10.0,
              'thumbnail': 'url',
              'stock': 5,
            },
          ],
        };

        when(mockDio.get(ApiUrls.products)).thenAnswer(
          (_) async => Response(
            data: mockResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: ApiUrls.products),
          ),
        );

        // Act
        final result = await repository.getProducts();

        // Assert
        expect(result.isRight(), true);
        result.fold((l) => fail('Should not return failure'), (r) {
          expect(r.length, 1);
          expect(r.first.title, 'Test Product');
        });
      },
    );

    test('should return ServerFailure when API call fails', () async {
      // Arrange
      when(mockDio.get(ApiUrls.products)).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiUrls.products),
          message: 'Server Error',
        ),
      );

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (r) => fail('Should not return success'),
      );
    });
  });
}
