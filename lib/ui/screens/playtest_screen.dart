import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:leyak_lvl_editor/editor/models/level_entity.dart';
import 'package:leyak_lvl_editor/game/playtest_game.dart';

enum _PlaytestOutcome { none, won, died }

/// Екран запуску гри — незалежний `GameWidget<PlaytestGame>` поза
/// редактором. [entities] — уже незалежний знімок (див. виклик на
/// [LevelEditorScreen], клонування через `EntitySnapshot`), тож нічого
/// тут не пише назад у дані редактора.
class PlaytestScreen extends StatefulWidget {
  const PlaytestScreen({
    super.key,
    required this.entities,
    required this.tileSize,
    required this.groundY,
  });

  final List<LevelEntity> entities;
  final double tileSize;
  final double groundY;

  @override
  State<PlaytestScreen> createState() => _PlaytestScreenState();
}

class _PlaytestScreenState extends State<PlaytestScreen> {
  late PlaytestGame _game;
  _PlaytestOutcome _outcome = _PlaytestOutcome.none;

  @override
  void initState() {
    super.initState();
    _game = _createGame();
  }

  PlaytestGame _createGame() => PlaytestGame(
    entities: widget.entities,
    tileSize: widget.tileSize,
    groundY: widget.groundY,
    onDeath: () => setState(() => _outcome = _PlaytestOutcome.died),
    onWin: () => setState(() => _outcome = _PlaytestOutcome.won),
  );

  void _retry() {
    setState(() {
      _outcome = _PlaytestOutcome.none;
      _game = _createGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GameWidget(key: ValueKey(_game), game: _game),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Back to editor',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (_outcome != _PlaytestOutcome.none)
            _OutcomeOverlay(
              won: _outcome == _PlaytestOutcome.won,
              onRetry: _retry,
              onExit: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }
}

class _OutcomeOverlay extends StatelessWidget {
  const _OutcomeOverlay({required this.won, required this.onRetry, required this.onExit});

  final bool won;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            won ? 'LEVEL COMPLETE' : 'GAME OVER',
            style: TextStyle(
              color: won ? Colors.greenAccent : Colors.redAccent,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              const SizedBox(width: 16),
              OutlinedButton(onPressed: onExit, child: const Text('Back to editor')),
            ],
          ),
        ],
      ),
    );
  }
}
