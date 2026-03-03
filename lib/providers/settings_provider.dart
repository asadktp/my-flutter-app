import 'package:flutter/material.dart';
import '../models/settings_model.dart';

class SettingsProvider with ChangeNotifier {
  SettingsModel _settings = SettingsModel();

  SettingsModel get settings => _settings;

  Future<void> updateSettings(SettingsModel newSettings) async {
    _settings = newSettings;
    notifyListeners();
  }
}
