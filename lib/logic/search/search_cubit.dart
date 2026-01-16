import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/repositories/product_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final ProductRepository _productRepository;

  SearchCubit(this._productRepository) : super(SearchInitial());

  final _searchController = StreamController<String>();

  void init() {
    _searchController.stream
        .debounceTime(const Duration(milliseconds: 500))
        .distinct()
        .listen((query) {
          _performSearch(query);
        });
  }

  void onSearchChanged(String query) {
    if (query.isNotEmpty) {
      _searchController.add(query);
    } else {
      emit(SearchInitial());
    }
  }

  Future<void> _performSearch(String query) async {
    emit(SearchLoading());
    final result = await _productRepository.searchProducts(query);
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (products) => emit(SearchLoaded(products)),
    );
  }

  @override
  Future<void> close() {
    _searchController.close();
    return super.close();
  }
}
