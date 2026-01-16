import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_urls.dart';
import '../../core/error/failures.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductRepository {
  final ApiService _apiService;

  // Local buffer to simulate persistence for dummyjson
  final List<Product> _localAddedProducts = [];
  final Map<int, Product> _localUpdatedProducts = {};
  final Set<int> _localDeletedProductIds = {};

  ProductRepository(this._apiService);

  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final response = await _apiService.dio.get(ApiUrls.categories);
      final List<dynamic> data = response.data;
      // DummyJSON sometimes returns list of strings or objects.
      // Based on recent docs it returns objects {slug, name, url}.
      // If straightforward strings, we need to map differently so let's handle safety if needed,
      // but assuming objects as per standard.
      // Actually, let's be safe: if it's a list of strings, map manually.

      if (data.isNotEmpty && data.first is String) {
        return Right(
          data.map((e) => Category(slug: e, name: e, url: '')).toList(),
        );
      }

      return Right(data.map((json) => Category.fromJson(json)).toList());
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to load categories'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Product>> getProductDetails(int id) async {
    try {
      await _loadLocalPersistence();
      // Check local updates first
      if (_localUpdatedProducts.containsKey(id)) {
        return Right(_localUpdatedProducts[id]!);
      }
      // Check added products
      final localAdded = _localAddedProducts.firstWhere(
        (p) => p.id == id,
        orElse: () => Product(
          id: -1,
          title: '',
          description: '',
          price: 0,
          thumbnail: '',
          stock: 0,
        ),
      );
      if (localAdded.id != -1) {
        return Right(localAdded);
      }

      final response = await _apiService.dio.get('${ApiUrls.products}/$id');
      return Right(Product.fromJson(response.data));
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to load product details'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      await _loadLocalPersistence();
      final response = await _apiService.dio.get(ApiUrls.products);
      final data = response.data;
      final products = (data['products'] as List)
          .map((json) => Product.fromJson(json))
          .toList();

      // Filter deleted
      var activeProducts = products
          .where((p) => !_localDeletedProductIds.contains(p.id))
          .toList();

      // Merge local updates
      final mergedProducts = activeProducts.map((p) {
        if (_localUpdatedProducts.containsKey(p.id)) {
          return _localUpdatedProducts[p.id]!;
        }
        return p;
      }).toList();

      // Append local additions (and filter deleted if somehow deleted)
      final localAdds = _localAddedProducts
          .where((p) => !_localDeletedProductIds.contains(p.id))
          .toList();

      return Right([...localAdds, ...mergedProducts]);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to load products'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Product>>> searchProducts(String query) async {
    try {
      await _loadLocalPersistence();
      final response = await _apiService.dio.get(
        ApiUrls.searchProducts,
        queryParameters: {'q': query},
      );
      final data = response.data;
      final products = (data['products'] as List)
          .map((json) => Product.fromJson(json))
          .toList();

      var activeProducts = products
          .where((p) => !_localDeletedProductIds.contains(p.id))
          .toList();

      // Merge local updates
      var mergedProducts = activeProducts.map((p) {
        if (_localUpdatedProducts.containsKey(p.id)) {
          return _localUpdatedProducts[p.id]!;
        }
        return p;
      }).toList();

      // Search local additions
      final localMatches = _localAddedProducts.where((p) {
        return !_localDeletedProductIds.contains(p.id) &&
            p.title.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return Right([...localMatches, ...mergedProducts]);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to search products'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, List<Product>>> getProductsByCategory(
    String categorySlug,
  ) async {
    try {
      await _loadLocalPersistence();
      final response = await _apiService.dio.get(
        '${ApiUrls.products}/category/$categorySlug',
      );
      final List<dynamic> productsJson = response.data['products'];
      final apiProducts = productsJson
          .map((json) => Product.fromJson(json))
          .toList();

      // 1. Remove deleted
      var filteredApi = apiProducts
          .where((p) => !_localDeletedProductIds.contains(p.id))
          .toList();

      // 2. Apply updates and check if they still belong to category
      var processedApi = <Product>[];
      for (var p in filteredApi) {
        if (_localUpdatedProducts.containsKey(p.id)) {
          final updated = _localUpdatedProducts[p.id]!;
          // If updated product category matches, include it
          // Note: Original API might not send category in product body sometimes, so be careful.
          // Logic: If updated has category, check it. If empty, assume stays (or check API logic).
          // User requirement: "if changed it will now show in new category and no longer show in old".
          if (updated.category == categorySlug) {
            processedApi.add(updated);
          }
          // else: it moved to another category, so don't add it.
        } else {
          processedApi.add(p);
        }
      }

      // 3. Find items from OTHER categories that were moved TO this one
      // This is hard to do without scanning all updated products.
      // Since local cache is small, we can scan `_localUpdatedProducts`.
      final movedInProducts = _localUpdatedProducts.values.where((p) {
        return p.category == categorySlug &&
            !productsJson.any(
              (json) => json['id'] == p.id,
            ) && // Avoid duplicates if already in list
            !_localDeletedProductIds.contains(p.id);
      });

      // 4. Add local additions for this category
      final localAdds = _localAddedProducts
          .where(
            (p) =>
                p.category == categorySlug &&
                !_localDeletedProductIds.contains(p.id),
          )
          .toList();

      return Right([...localAdds, ...processedApi, ...movedInProducts]);
    } on DioException catch (e) {
      return Left(
        ServerFailure(e.message ?? 'Failed to load category products'),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Product>> addProduct(
    Map<String, dynamic> productData,
  ) async {
    try {
      final response = await _apiService.dio.post(
        ApiUrls.addProduct,
        data: productData,
      );
      // Ensure category is preserved from input if API doesn't return it
      var newProduct = Product.fromJson(response.data);
      if (productData.containsKey('category')) {
        newProduct = newProduct.copyWith(category: productData['category']);
      }
      if (productData.containsKey('thumbnail')) {
        newProduct = newProduct.copyWith(thumbnail: productData['thumbnail']);
      }

      // Ensure ID uniqueness for local logic (random > 1000)
      if (_localAddedProducts.any((p) => p.id == newProduct.id)) {
        newProduct = newProduct.copyWith(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
        );
      }

      _localAddedProducts.insert(0, newProduct);
      await _saveLocalPersistence();
      return Right(newProduct);
    } on DioException catch (e) {
      return Left(ServerFailure(e.message ?? 'Failed to add product'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, Product>> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    try {
      // Local addition update
      if (_localAddedProducts.any((p) => p.id == id)) {
        final index = _localAddedProducts.indexWhere((p) => p.id == id);
        if (index != -1) {
          final existing = _localAddedProducts[index];
          final updated = existing.copyWith(
            title: productData['title'] as String?,
            price: productData['price'] as double?,
            description: productData['description'] as String?,
            category: productData['category'] as String?,
            thumbnail: productData['thumbnail'] as String?,
          );
          _localAddedProducts[index] = updated;
          await _saveLocalPersistence();
          return Right(updated);
        }
      }

      final response = await _apiService.dio.put(
        '${ApiUrls.products}/$id',
        data: productData,
      );
      var updatedProduct = Product.fromJson(response.data);
      // Manually set category if API didn't return it or we want to enforce user choice
      if (productData.containsKey('category')) {
        updatedProduct = updatedProduct.copyWith(
          category: productData['category'],
        );
      }
      if (productData.containsKey('thumbnail')) {
        updatedProduct = updatedProduct.copyWith(
          thumbnail: productData['thumbnail'],
        );
      }

      _localUpdatedProducts[id] = updatedProduct;
      return Right(updatedProduct);
    } on DioException catch (e) {
      // Fallback for local simulation
      if (_localUpdatedProducts.containsKey(id) || id > 100) {
        // Construct simulated object
        // Note: This is a bit risky but necessary if API fails
        // ... (simplified logic)
        return Left(ServerFailure(e.toString()));
      }
      return Left(ServerFailure(e.message ?? 'Failed to update product'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteProduct(int id) async {
    _localDeletedProductIds.add(id);
    _localAddedProducts.removeWhere((p) => p.id == id);
    await _saveLocalPersistence();
    _localUpdatedProducts.remove(id);

    // In a real app we would call DELETE API
    // try {
    //   await _apiService.dio.delete('${ApiUrls.products}/$id');
    // } catch (e) { ... }

    return const Right(null);
  }

  // --- Persistence Logic ---

  Future<void> _loadLocalPersistence() async {
    if (_localAddedProducts.isNotEmpty) return; // Already loaded

    final prefs = await SharedPreferences.getInstance();
    final String? addedProductsJson = prefs.getString('local_added_products');
    if (addedProductsJson != null) {
      final List<dynamic> decoded = jsonDecode(addedProductsJson);
      _localAddedProducts.clear();
      _localAddedProducts.addAll(
        decoded.map((e) => Product.fromJson(e)).toList(),
      );
    }
  }

  Future<void> _saveLocalPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _localAddedProducts.map((p) => p.toJson()).toList(),
    );
    await prefs.setString('local_added_products', encoded);
  }
}
