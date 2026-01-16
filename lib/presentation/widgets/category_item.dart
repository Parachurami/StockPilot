import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/product_repository.dart';
import '../../logic/category/category_product_cubit.dart';
import '../screens/category_screen.dart';

class CategoryItem extends StatelessWidget {
  final Category category;

  const CategoryItem({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    IconData getIcon(String slug) {
      if (slug.contains('beauty') || slug.contains('skin')) {
        return Icons.face_retouching_natural;
      }
      if (slug.contains('fragrance')) return Icons.local_florist;
      if (slug.contains('furniture')) return Icons.chair_outlined;
      if (slug.contains('groceries')) return Icons.local_grocery_store_outlined;
      if (slug.contains('home-decoration')) {
        return Icons.light; // Changed to match a home item
      }
      if (slug.contains('kitchen')) return Icons.kitchen;
      if (slug.contains('laptop')) return Icons.laptop_mac;
      if (slug.contains('mens')) return Icons.checkroom;
      if (slug.contains('womens')) return Icons.woman;
      if (slug.contains('vehicle') || slug.contains('motorcycle')) {
        return Icons.directions_car_filled;
      }
      if (slug.contains('mobile') || slug.contains('phone')) {
        return Icons.phone_iphone;
      }
      return Icons.category_outlined;
    }

    // Capitalize first letter
    String label = category.name;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Capture repository from the current context
          final productRepository = context.read<ProductRepository>();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => CategoryProductCubit(productRepository),
                child: CategoryScreen(category: category),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Icon(
                getIcon(category.slug),
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                // color removed to use default theme color which is white in dark mode
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
