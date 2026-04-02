import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static Future<SharedPreferences> instance() => SharedPreferences.getInstance();
}

