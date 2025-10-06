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
  set serverUri(String uri) {
    if (Uri.tryParse(uri) != null)
      _storage!.setString("_SERVER_URI", uri);
    else TommyLogger.logger.error("Cannot parse uri: $uri", 3000);
  }

  // _SERVER_SCORES_FILE
  String get scoresFilename => _storage!.getString("_SERVER_SCORES_FILE") ?? "!scores.txt";
  set scoresFilename(String name) {
    if (name.isNotEmpty)
      _storage!.setString("_SERVER_SCORES_FILE", name);
  }

  // _MIN_STARS_TO_PLAY
  int get minStarsToPlay => _storage!.getInt("_MIN_STARS_TO_PLAY") ?? 0; // 0 = play all
  set minStarsToPlay(int stars) {
    if (0 <= stars && stars <= 5)
      _storage!.setInt("_MIN_STARS_TO_PLAY", stars);
  }

  // stars (song name = key)
  int getStars(String song) => _storage!.getInt(song) ?? 0;
  void setStars(String song, int stars) {
    if (song.isNotEmpty)
      _storage!.setInt(song, stars);
  }

  // get all scores
  List<String> get appKeys => _storage!.getKeys().where((key) => !key.startsWith("_")).toList();

  // app version
  String get version => "${_info!.appName} v${_info!.version} build ${_info!.buildNumber}";
}
