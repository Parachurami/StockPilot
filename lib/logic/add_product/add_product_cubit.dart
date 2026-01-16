import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/product_repository.dart';
import 'add_product_state.dart';

class AddProductCubit extends Cubit<AddProductState> {
  final ProductRepository _productRepository;

  AddProductCubit(this._productRepository) : super(AddProductInitial()) {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    emit(const AddProductLoading(isLoadingCategories: true));
    final result = await _productRepository.getCategories();
    result.fold(
      (failure) => emit(
        const AddProductError('Failed to load categories'),
      ), // Handle error gracefully
      (categories) => emit(CategoriesLoaded(categories)),
    );
  }

  Future<void> submitProduct(Map<String, dynamic> productData) async {
    // Preserve current categories
    final currentCategories = state.categories;
    emit(AddProductLoading(categories: currentCategories));

    final result = await _productRepository.addProduct(productData);
    result.fold(
      (failure) =>
          emit(AddProductError(failure.message, categories: currentCategories)),
      (product) => emit(
        AddProductSuccess(
          'Product added successfully',
          product: product,
          categories: currentCategories,
        ),
      ),
    );
  }

  Future<void> updateProduct(int id, Map<String, dynamic> productData) async {
    final currentCategories = state.categories;
    emit(AddProductLoading(categories: currentCategories));

    final result = await _productRepository.updateProduct(id, productData);
    result.fold(
      (failure) =>
          emit(AddProductError(failure.message, categories: currentCategories)),
      (product) => emit(
        AddProductSuccess(
          'Product updated successfully',
          product: product,
          categories: currentCategories,
        ),
      ),
    );
  }
}
