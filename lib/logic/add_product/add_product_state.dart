import 'package:equatable/equatable.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';

class AddProductState extends Equatable {
  final List<Category> categories;
  final bool isLoadingCategories;

  const AddProductState({
    this.categories = const [],
    this.isLoadingCategories = false,
  });

  @override
  List<Object> get props => [categories, isLoadingCategories];
}

class AddProductInitial extends AddProductState {}

class AddProductLoading extends AddProductState {
  const AddProductLoading({super.categories, super.isLoadingCategories});
}

class AddProductSuccess extends AddProductState {
  final String message;
  final Product? product;

  const AddProductSuccess(
    this.message, {
    this.product,
    super.categories,
    super.isLoadingCategories,
  });

  @override
  List<Object> get props => [
    message,
    if (product != null) product!,
    categories,
    isLoadingCategories,
  ];
}

class AddProductError extends AddProductState {
  final String message;

  const AddProductError(
    this.message, {
    super.categories,
    super.isLoadingCategories,
  });

  @override
  List<Object> get props => [message, categories, isLoadingCategories];
}

class CategoriesLoaded extends AddProductState {
  const CategoriesLoaded(List<Category> categories)
    : super(categories: categories, isLoadingCategories: false);
}
