import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/family_health/presentation/pages/dash_board_screen.dart';
import 'features/family_health/family_health_dependencies.dart';
import 'features/family_health/domain/usecases/load_family_health.dart';
import 'features/family_health/presentation/bloc/health_bloc.dart';
import 'features/family_health/presentation/bloc/health_event.dart';

void main() => runApp(const FamilyHealthApp());

class FamilyHealthApp extends StatelessWidget {
  const FamilyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111820);
    const canvas = Color(0xFFF5F7F5);
    return BlocProvider(
      create: (_) => HealthBloc(
        LoadFamilyHealth(
          createFamilyHealthRepository(),
        ),
      )..add(LoadHealthData()),
      child: MaterialApp(
        title: 'Kinwell • Family Health',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF247A68),
            brightness: Brightness.light,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: canvas,
            foregroundColor: ink,
            elevation: 0,
            centerTitle: false,
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFE1F1EB),
            labelTextStyle: WidgetStateProperty.all(
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
        ),
        home: const DashBoardScreen(),
      ),
    );
  }
}
