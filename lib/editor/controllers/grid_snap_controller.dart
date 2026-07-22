/// Єдина відповідальність — стан "прилипання до сітки" (увімкнено/вимкнено)
/// і сповіщення про його зміну. Нічого не знає про клавіатуру чи UI.
class GridSnapController {
  GridSnapController({this.onSnapChanged});

  bool _snapEnabled = true;
  void Function(bool snapEnabled)? onSnapChanged;

  bool get snapEnabled => _snapEnabled;

  void toggle() {
    _snapEnabled = !_snapEnabled;
    onSnapChanged?.call(_snapEnabled);
  }
}
