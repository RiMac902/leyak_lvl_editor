import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/ui/screens/menu_screen.dart';

/// Main App Widget
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geometry Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MenuScreen(),
    );
  }
}
