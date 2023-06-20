import 'package:shared_preferences/shared_preferences.dart';

class KeyRepository {
  static const String keyHandleKey = 'KEY_HANDLE';

  static Future<String?> loadKeyHandle(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? key = prefs.getString('${KeyRepository.keyHandleKey}#$username');
    return key;
  }

  static Future<void> storeKeyHandle(String keyHandle, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String k = '${KeyRepository.keyHandleKey}#$username';
    await prefs.setString(k, keyHandle);
  }

  static Future<void> removeAllKeys() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.getKeys().forEach((key) => prefs.remove(key));
  }
}
