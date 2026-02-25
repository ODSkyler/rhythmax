import 'package:flutter/widgets.dart';
import 'theme_controller.dart';

class ThemeScope extends InheritedWidget {
  final ThemeController controller;

  const ThemeScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static ThemeController of(BuildContext context) {
    final scope =
    context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    if (scope == null) {
      throw Exception('ThemeScope not found in widget tree');
    }
    return scope.controller;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) =>
      oldWidget.controller != controller;
}
