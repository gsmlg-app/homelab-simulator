import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

import 'screens/game_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HomelabSimulatorApp());
}

class HomelabSimulatorApp extends StatelessWidget {
  const HomelabSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GameBloc()..add(const GameInitialize())),
        BlocProvider(create: (_) => WorldBloc()),
      ],
      child: MaterialApp(
        title: 'Homelab Simulator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0D0D1A),
          colorScheme: ColorScheme.dark(
            primary: Colors.cyan.shade400,
            secondary: Colors.green.shade400,
          ),
        ),
        home: const GameScreen(),
      ),
    );
  }
}
