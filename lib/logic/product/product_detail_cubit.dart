import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import 'product_detail_state.dart';

class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductRepository _productRepository;

  ProductDetailCubit(this._productRepository) : super(ProductDetailInitial());

  Future<void> loadProductDetails(int id) async {
    emit(ProductDetailLoading());
    final result = await _productRepository.getProductDetails(id);
    result.fold(
      (failure) => emit(ProductDetailError(failure.message)),
      (product) => emit(ProductDetailLoaded(product)),
    );
  }

  void updateLocalProduct(Product product) {
    emit(ProductDetailLoaded(product));
  }
}
