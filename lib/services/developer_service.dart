import '../services/storage_service.dart';

class DeveloperService {
  static const String _developerModeKey = 'developer_mode_enabled';
  static const String _developerPasswordKey = 'developer_password_hash';

  // Default developer password (you can change this)
  static const String _defaultPassword = 'dev123';

  /// Check if developer mode is currently enabled
  static Future<bool> isDeveloperModeEnabled() async {
    final enabled = await StorageService.loadBool(_developerModeKey);
    return enabled ?? false;
  }

  /// Enable developer mode
  static Future<void> enableDeveloperMode() async {
    await StorageService.saveBool(_developerModeKey, true);
  }

  /// Disable developer mode
  static Future<void> disableDeveloperMode() async {
    await StorageService.saveBool(_developerModeKey, false);
  }

  /// Verify the developer password
  static Future<bool> verifyPassword(String inputPassword) async {
    // For now, we'll use a simple comparison
    // In a real app, you'd want to hash the password
    return inputPassword == _defaultPassword;
  }

  /// Check if password is set (for future use if you want to allow custom passwords)
  static Future<bool> hasPasswordSet() async {
    final hasPassword = await StorageService.loadString(_developerPasswordKey);
    return hasPassword != null;
  }

  /// Set a custom developer password (for future use)
  static Future<void> setPassword(String newPassword) async {
    // In a real implementation, you'd hash this password
    await StorageService.saveString(_developerPasswordKey, newPassword);
  }
}
