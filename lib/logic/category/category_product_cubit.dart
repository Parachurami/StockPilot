import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/product_repository.dart';
import 'category_product_state.dart';

class CategoryProductCubit extends Cubit<CategoryProductState> {
  final ProductRepository _productRepository;

  CategoryProductCubit(this._productRepository)
    : super(CategoryProductInitial());

  Future<void> loadProducts(String categorySlug) async {
    if (state is! CategoryProductLoaded) {
      emit(CategoryProductLoading());
    }
    final result = await _productRepository.getProductsByCategory(categorySlug);
    result.fold(
      (failure) => emit(CategoryProductError(failure.message)),
      (products) => emit(
        CategoryProductLoaded(
          allProducts: products,
          filteredProducts: products,
        ),
      ),
    );
  }

  void filterProducts(String query) {
    if (state is CategoryProductLoaded) {
      final currentState = state as CategoryProductLoaded;
      if (query.isEmpty) {
        emit(
          CategoryProductLoaded(
            allProducts: currentState.allProducts,
            filteredProducts: currentState.allProducts,
          ),
        );
      } else {
        final filtered = currentState.allProducts.where((product) {
          return product.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
        emit(
          CategoryProductLoaded(
            allProducts: currentState.allProducts,
            filteredProducts: filtered,
          ),
        );
      }
    }
  }

  Future<void> deleteProduct(int id) async {
    if (state is CategoryProductLoaded) {
      final currentState = state as CategoryProductLoaded;

      // Optimistically update
      final updatedAll = currentState.allProducts
          .where((p) => p.id != id)
          .toList();
      final updatedFiltered = currentState.filteredProducts
          .where((p) => p.id != id)
          .toList();

      emit(
        CategoryProductLoaded(
          allProducts: updatedAll,
          filteredProducts: updatedFiltered,
        ),
      );

      await _productRepository.deleteProduct(id);
    }
  }
}
