import 'package:equatable/equatable.dart';
import '../../data/models/product_model.dart';

abstract class CategoryProductState extends Equatable {
  const CategoryProductState();

  @override
  List<Object> get props => [];
}

class CategoryProductInitial extends CategoryProductState {}

class CategoryProductLoading extends CategoryProductState {}

class CategoryProductLoaded extends CategoryProductState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;

  const CategoryProductLoaded({
    required this.allProducts,
    required this.filteredProducts,
  });

  @override
  List<Object> get props => [allProducts, filteredProducts];
}

class CategoryProductError extends CategoryProductState {
  final String message;

  const CategoryProductError(this.message);

  @override
  List<Object> get props => [message];
}
