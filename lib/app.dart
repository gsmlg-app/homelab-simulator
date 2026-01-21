import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:app_lib_core/app_lib_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

import 'screens/start_menu_screen.dart';

/// Root application widget providing BLoC state management.
///
/// Creates and manages [GameBloc] and [WorldBloc] instances, handling
/// lifecycle events to auto-save game state when the app goes to background.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  late final GameBloc _gameBloc;
  late final WorldBloc _worldBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gameBloc = GameBloc()..add(const GameInitialize());
    _worldBloc = WorldBloc();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gameBloc.close();
    _worldBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Auto-save when app goes to background
        _gameBloc.add(const GameSave());
        break;
      case AppLifecycleState.resumed:
        // App resumed - could refresh state if needed
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _gameBloc),
        BlocProvider.value(value: _worldBloc),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: const Key('homelab_simulator_app'),
      debugShowCheckedModeBanner: false,
      title: 'Homelab Simulator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.cyan400,
          secondary: AppColors.green400,
        ),
      ),
      home: const StartMenuScreen(),
    );
  }
}
