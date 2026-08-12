import 'package:flutter/material.dart';

/// Кнопка-питання, що відкриває довідку з усіх клавіатурних шорткатів
/// редактора (див. `lib/editor/input/`). Список веде статично, а не
/// зчитує біндінги з класів шорткатів — вони маленькі й стабільні, тож
/// окрема геттер-обгортка над кожним ради UI-довідки не виправдана.
class ShortcutsHelpButton extends StatelessWidget {
  const ShortcutsHelpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'shortcuts-help',
      backgroundColor: Colors.black87,
      tooltip: 'Keyboard shortcuts',
      onPressed: () => showDialog<void>(context: context, builder: (_) => const _ShortcutsDialog()),
      child: const Icon(Icons.keyboard_alt_outlined),
    );
  }
}

class _ShortcutsDialog extends StatelessWidget {
  const _ShortcutsDialog();

  static const List<(String, List<(String, String)>)> _sections = [
    (
      'Modes',
      [
        ('F', 'Draw / Forms'),
        ('S', 'Select & Move'),
        ('P', 'Player Spawn'),
        ('C', 'Camera Path'),
      ],
    ),
    (
      'Editing selection',
      [
        ('Ctrl/Cmd + D', 'Duplicate'),
        ('Delete / Backspace', 'Delete'),
        ('Ctrl/Cmd + G', 'Group'),
        ('Ctrl/Cmd + Shift + G', 'Ungroup'),
        ('Ctrl/Cmd + M', 'Merge'),
      ],
    ),
    (
      'History',
      [
        ('Ctrl/Cmd + Z', 'Undo'),
        ('Ctrl/Cmd + Shift + Z, or Ctrl + Y', 'Redo'),
      ],
    ),
    (
      'Grid',
      [('G', 'Toggle snap to grid')],
    ),
    (
      'Path tool (Pen, while drawing)',
      [
        ('Enter', 'Finish contour'),
        ('Escape', 'Cancel contour'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Keyboard shortcuts',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final section in _sections) _Section(section)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.section);

  final (String, List<(String, String)>) section;

  @override
  Widget build(BuildContext context) {
    final (title, entries) = section;
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          for (final (keys, label) in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      keys,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
