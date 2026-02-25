import 'package:flutter/material.dart';

abstract class SourceSettings {
  /// Human readable title (e.g. "JioSaavn Settings")
  String get title;
  
  /// Optional logo shown in source card
  Widget? buildLogo(BuildContext context) => null;

  /// Called when source is ACTIVE
  Widget buildSettings(BuildContext context);
}
