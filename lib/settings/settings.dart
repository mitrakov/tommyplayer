// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tommyplayer/tommylogger.dart';

// TODO: change to idiomatic way (see project "LasNotes" Flutter)
class Settings {
  static const String _serverUriKey  = "_SERVER_URI";
  static const String _scoresFileKey = "_SERVER_SCORES_FILE";
  static const String _minStarsKey   = "_MIN_STARS_TO_PLAY";

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
    return _storage!.getString(_serverUriKey) ?? "http://mitrakoff.ru/music";
  }

  String getScoresFilename() {
    _check();
    return _storage!.getString(_scoresFileKey) ?? "!scores.txt";
  }

  List<String> getAppKeys() {
    _check();
    return _storage!.getKeys().where((key) => !key.startsWith("_")).toList();
  }

  int getStars(String song) {
    _check();
    return _storage!.getInt(song) ?? 0;
  }

  int getMinStarsToPlay() {
    _check();
    return _storage!.getInt(_minStarsKey) ?? 0; // 0 = all songs
  }

  String getVersion() {
    _check();
    return "${_info!.appName} v${_info!.version} build ${_info!.buildNumber}";
  }

  Future<bool> setServerUri(String uri) {
    _check();
    try {
      Uri.parse(uri); // additional check
      return _storage!.setString(_serverUriKey, uri);
    } catch (e) {
      TommyLogger.logger.error("Cannot parse uri: $uri ($e)", 3000);
      return Future.value(false);
    }
  }

  Future<bool> setStars(String song, int stars) {
    _check();
    if (song.isNotEmpty)
      return _storage!.setInt(song, stars);
    return Future.value(false);
  }

  Future<bool> setMinStarsToPlay(int stars) {
    _check();
    if (0 <= stars && stars <= 5)
      return _storage!.setInt(_minStarsKey, stars);
    return Future.value(false);
  }

  Future<bool> setScoresFilename(String name) {
    _check();
    if (name.isNotEmpty)
      return _storage!.setString(_scoresFileKey, name);
    return Future.value(false);
  }

  void _check() {
    if (_storage == null || _info == null) throw Exception("ERROR: call Settings.instance.init() in main app widget");
  }
}
