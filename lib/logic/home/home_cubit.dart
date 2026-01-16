import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final ProductRepository _productRepository;

  HomeCubit(this._productRepository) : super(HomeInitial());

  Future<void> loadDashboardData() async {
    try {
      emit(HomeLoading());

      // Fetch both categories and products
      final categoriesResult = await _productRepository.getCategories();
      final productsResult = await _productRepository.getProducts();

      categoriesResult.fold((failure) => emit(HomeError(failure.message)), (
        categories,
      ) {
        // Handle products result inside categories success
        productsResult.fold((failure) => emit(HomeError(failure.message)), (
          products,
        ) {
          final distinctSlugs = [
            'beauty',
            'furniture',
            'groceries',
            'laptops',
            'mens-shirts',
            'vehicle',
          ];

          final filteredCategories = categories
              .where((c) {
                return distinctSlugs.any(
                  (element) => c.slug == element || c.slug.contains(element),
                );
              })
              .take(6)
              .toList();

          emit(HomeLoaded(categories: filteredCategories, products: products));
        });
      });
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void addProduct(Product product) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final updatedProducts = [product, ...currentState.products];
      emit(
        HomeLoaded(
          categories: currentState.categories,
          products: updatedProducts,
        ),
      );
    }
  }

  void updateProduct(Product product) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final updatedProducts = currentState.products.map((p) {
        return p.id == product.id ? product : p;
      }).toList();
      emit(
        HomeLoaded(
          categories: currentState.categories,
          products: updatedProducts,
        ),
      );
    }
  }

  Future<void> deleteProduct(int id) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;

      // Optimistically update UI
      final updatedProducts = currentState.products
          .where((p) => p.id != id)
          .toList();
      emit(
        HomeLoaded(
          categories: currentState.categories,
          products: updatedProducts,
        ),
      );

      // Call repo
      await _productRepository.deleteProduct(id);
    }
  }
}
