// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tommyplayer/tommylogger.dart';

class Settings {
  Settings._();
  static final Settings _instance = Settings._();
  static SharedPreferences? _storage;
  static PackageInfo? _info;
  static Future<void> init() async {
    _storage = await SharedPreferences.getInstance();
    _info = await PackageInfo.fromPlatform();
  }
  static Settings get local {
    if (_storage != null) return _instance; else throw Exception("Settings are not initialized. Call Settings.instance.init() first");
  }

  // _SERVER_URI
  String get serverUri => _storage!.getString("_SERVER_URI") ?? "http://mitrakoff.ru/music";
  Future<void> setServerUri(String uri) async {
    if (Uri.tryParse(uri) != null)
      await _storage!.setString("_SERVER_URI", uri);
    else TommyLogger.logger.error("Cannot parse uri: $uri", 3000);
  }

  // _SERVER_SCORES_FILE
  String get scoresFilename => _storage!.getString("_SERVER_SCORES_FILE") ?? "!scores.txt";
  Future<void> setScoresFilename(String name) async {
    if (name.isNotEmpty)
      await _storage!.setString("_SERVER_SCORES_FILE", name);
  }

  // _MIN_STARS_TO_PLAY
  int get minStarsToPlay => _storage!.getInt("_MIN_STARS_TO_PLAY") ?? 0; // 0 = play all
  Future<void> setMinStarsToPlay(int stars) async {
    if (0 <= stars && stars <= 5)
      await _storage!.setInt("_MIN_STARS_TO_PLAY", stars);
  }

  // stars (song name = key)
  int getStars(String song) => _storage!.getInt(song) ?? 0;
  Future<void> setStars(String song, int stars) async {
    if (song.isNotEmpty)
      await _storage!.setInt(song, stars);
  }

  // get all scores
  List<String> get appKeys => _storage!.getKeys().where((key) => !key.startsWith("_")).toList();

  // app version
  String get version => "${_info!.appName} v${_info!.version} build ${_info!.buildNumber}";
}
