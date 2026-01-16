import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/services/api_service.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/home/home_cubit.dart';
import 'presentation/screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ApiService apiService = ApiService(); // Instantiated ApiService

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository(apiService)),
        RepositoryProvider(
          create: (context) => ProductRepository(apiService),
        ), // Added ProductRepository
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>()),
          ), // Updated AuthBloc creation
          BlocProvider(
            create: (context) =>
                HomeCubit(context.read<ProductRepository>())
                  ..loadDashboardData(),
          ),
        ],
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          child: MaterialApp(
            title: 'StockPilot',
            theme: AppTheme.lightTheme,
            home: const LoginScreen(),
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}
