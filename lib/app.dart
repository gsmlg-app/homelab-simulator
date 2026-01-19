import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_bloc_game/app_bloc_game.dart';
import 'package:game_bloc_world/game_bloc_world.dart';

import 'screens/start_menu_screen.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan.shade400,
          secondary: Colors.green.shade400,
        ),
      ),
      home: const StartMenuScreen(),
    );
  }
}
