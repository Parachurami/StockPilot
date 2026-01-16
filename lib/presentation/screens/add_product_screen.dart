import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../logic/add_product/add_product_cubit.dart';
import '../../logic/add_product/add_product_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/mock_image_item.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';

class AddProductScreen extends StatelessWidget {
  final Product? product; // If provided, we are in Edit Mode

  const AddProductScreen({super.key, this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddProductCubit(context.read<ProductRepository>()),
      child: _AddProductView(product: product),
    );
  }
}

class _AddProductView extends StatefulWidget {
  final Product? product;

  const _AddProductView({this.product});

  @override
  State<_AddProductView> createState() => _AddProductViewState();
}

class _AddProductViewState extends State<_AddProductView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;

  String? _selectedCategory;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(text: product?.title ?? '');
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    // Pre-select category if available.
    // Note: The product model might store category as a string slug or ID.
    // We assume here it matches the slug format.
    if (product != null && product.category.isNotEmpty) {
      _selectedCategory = product.category;
    }
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint('Image Picker Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final productData = {
        'title': _titleController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'description': _descriptionController.text,
        'category': _selectedCategory ?? '',
        if (_selectedImage != null) 'thumbnail': _selectedImage!.path,
      };

      if (widget.product != null) {
        context.read<AddProductCubit>().updateProduct(
          widget.product!.id,
          productData,
        );
      } else {
        context.read<AddProductCubit>().submitProduct(productData);
      }
    }
  }

  String _getUserFriendlyError(String backendError) {
    if (backendError.contains('Network') ||
        backendError.contains('connection')) {
      return 'Please check your internet connection.';
    }
    if (backendError.contains('timeout')) {
      return 'The server is taking too long to respond. Please try again.';
    }
    if (backendError.contains('404')) {
      return 'Service not found. Please contact support.';
    }
    if (backendError.contains('500')) {
      return 'Something went wrong on our end. Please try again later.';
    }
    return backendError.isNotEmpty
        ? '${backendError[0].toUpperCase()}${backendError.substring(1)}'
        : 'An unexpected error occurred.';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return BlocListener<AddProductCubit, AddProductState>(
      listener: (context, state) {
        if (state is AddProductSuccess) {
          // Return the result to the previous screen to handle the toast
          Navigator.pop(context, state.product);
        } else if (state is AddProductError) {
          // Keep showing error toast here as we are still on this screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_getUserFriendlyError(state.message)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: Container(
            height: 50,
            width: 50,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Center(
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          title: Text(
            isEditing ? 'Edit Product' : 'Add Product',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photos Section
                const SectionHeader(title: 'Photos'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Display Selected Image
                      if (_selectedImage != null)
                        Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_selectedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else ...[
                        MockImageItem(
                          url:
                              widget.product?.thumbnail ??
                              'https://i.dummyjson.com/data/products/1/thumbnail.jpg',
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Add Button
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.2),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Icon(
                                Icons.add_a_photo,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Category Variation Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const SectionHeader(title: 'Category Variation')],
                ),
                const SizedBox(height: 12),
                BlocBuilder<AddProductCubit, AddProductState>(
                  builder: (context, state) {
                    if (state.isLoadingCategories && state.categories.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final categories = state.categories;
                    if (categories.isEmpty) {
                      return const Text(
                        'No categories found',
                        style: TextStyle(color: AppColors.textSecondary),
                      );
                    }

                    return SizedBox(
                      height: 160,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 12,
                          runSpacing: 12,
                          children: categories.map((category) {
                            final isSelected =
                                category.slug == _selectedCategory;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category.slug;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Details Section
                const SectionHeader(title: 'About this product'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: _titleController,
                        hintText: 'Product Title',
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _priceController,
                        hintText: 'Price (\$)',
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a price'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'Description',
                        maxLines: 4,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a description'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Save Button
                BlocBuilder<AddProductCubit, AddProductState>(
                  builder: (context, state) {
                    return PrimaryButton(
                      text: isEditing ? 'Update Product' : 'Save Product',
                      isLoading: state is AddProductLoading,
                      onPressed: _submit,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
