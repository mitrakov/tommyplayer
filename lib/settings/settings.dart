// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static const String _serverUriKey = "_SERVER_URI";

  Settings._();
  static final Settings _instance = Settings._();
  static Settings get instance => _instance;

  SharedPreferences? _storage;
  PackageInfo? _info;

  Future<void> init() async {
    _storage ??= await SharedPreferences.getInstance();
    _info ??= await PackageInfo.fromPlatform();
  }

  String getServerUri() {
    _check();
    return _storage!.getString(_serverUriKey) ?? "http://mitrakoff.com:2000/music";
  }

  int? getStars(String song) {
    _check();
    return _storage!.getInt(song);
  }

  String getVersion() {
    _check();
    return "${_info!.appName} v${_info!.version} build ${_info!.buildNumber}";
  }

  Future<bool> setServerUri(String uri) {
    _check();
    return _storage!.setString(_serverUriKey, uri);
  }

  Future<bool> setStars(String song, int stars) {
    _check();
    return _storage!.setInt(song, stars);
  }

  void _check() {
    if (_storage == null || _info == null) throw Exception("Call Settings.init() in main app widget");
  }
}
