import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/ui/screens/level_editor_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'GEO GAME',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                color: Colors.white,
                shadows: [Shadow(color: Colors.white54, blurRadius: 24)],
              ),
            ),
            const SizedBox(height: 64),
            // _MenuButton(
            //   text: 'PLAY',
            //   onPressed: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (_) => const LevelSelectScreen()),
            //   ),
            // ),
            const SizedBox(height: 16),
            _MenuButton(
              text: 'EDITOR',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LevelEditorScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        side: const BorderSide(color: Colors.white30),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
      ),
    );
  }
}
