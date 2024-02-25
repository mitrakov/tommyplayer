// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static SharedPreferences? _storage;
  static const String _serverUriKey = "serverUri";

  static Future<void> init() async {
    _storage ??= await SharedPreferences.getInstance();
  }

  static String getServerUri() {
    _check();
    return _storage!.getString(_serverUriKey) ?? "http://mitrakoff.com:2000/music";
  }

  static void setServerUri(String uri) {
    _check();
    _storage!.setString(_serverUriKey, uri);
  }

  static void _check() {
    if (_storage == null) throw Exception("Call Settings.init() in main app widget");
  }
}
