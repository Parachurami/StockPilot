import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product_model.dart';

import 'package:fluttertoast/fluttertoast.dart';
import '../../logic/auth/auth_bloc.dart';
import '../../logic/auth/auth_event.dart';
import '../../logic/auth/auth_state.dart';
import '../../logic/home/home_cubit.dart';
import '../../logic/home/home_state.dart';

import '../widgets/category_item.dart';
import '../widgets/draggable_product_card.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    String firstName = 'Pilot';
    final state = context.watch<AuthBloc>().state;
    if (state is AuthSuccess) {
      firstName = state.user.firstName;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Custom Header
            Container(
              padding: const EdgeInsets.only(
                top: 60,
                left: 24,
                right: 24,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white24,
                            backgroundImage: state is AuthSuccess
                                ? NetworkImage(state.user.image)
                                : null,
                            child: state is! AuthSuccess
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Hello, $firstName!',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.logout,
                                color: Theme.of(context).iconTheme.color,
                              ),
                              onPressed: () {
                                context.read<AuthBloc>().add(LogoutRequested());
                                Fluttertoast.showToast(
                                  msg: "Logged out successfully",
                                  backgroundColor: AppColors.primary,
                                  textColor: Colors.white,
                                );
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Total Inventory',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$12,450.00',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+\$242.54 (2.93%)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // List Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Categories Section
                    SizedBox(
                      height: 110,
                      child: BlocBuilder<HomeCubit, HomeState>(
                        builder: (context, state) {
                          Widget content;
                          if (state is HomeLoading) {
                            content = const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is HomeLoaded) {
                            content = ListView.separated(
                              key: const ValueKey('CategoriesList'),
                              scrollDirection: Axis.horizontal,
                              itemCount: state.categories.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 20),
                              itemBuilder: (context, index) {
                                return CategoryItem(
                                  category: state.categories[index],
                                );
                              },
                            );
                          } else if (state is HomeError) {
                            content = Center(
                              child: Text('Error: ${state.message}'),
                            );
                          } else {
                            content = const SizedBox.shrink();
                          }
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            child: content,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Search Bar
                    const HomeSearchBar(),

                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    // Products List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await context.read<HomeCubit>().loadDashboardData();
                        },
                        child: BlocBuilder<HomeCubit, HomeState>(
                          builder: (context, state) {
                            if (state is HomeLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (state is HomeLoaded) {
                              return ListView.separated(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: state.products.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return DraggableProductCard(
                                    key: ValueKey(state.products[index].id),
                                    product: state.products[index],
                                    onDelete: () {
                                      context.read<HomeCubit>().deleteProduct(
                                        state.products[index].id,
                                      );
                                    },
                                    child: ProductCard(
                                      product: state.products[index],
                                    ),
                                  );
                                },
                              );
                            } else if (state is HomeError) {
                              return Center(
                                child: Text('Error: ${state.message}'),
                              );
                            }
                            return ListView(); // Empty list for initial state ensuring RefreshIndicator works
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddProductScreen()),
            );

            if (result != null && result is Product && context.mounted) {
              context.read<HomeCubit>().addProduct(result);
            }
          },
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
