// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:math';
import 'package:f_logs/f_logs.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:tommyplayer/settings/settings.dart';

/// Main model class
class MyModel extends Model {
  static const THROTTLING_MSEC = 1000; // performance: sleep N msec between each feed to Player instance
  static const MAX_PLAYLIST = 400; // performance: load no more that N songs to Player instance

  // vals
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  final List<String> _playlist = [];
  Stream<String> _playlistStream = const Stream.empty();

  // getters
  /// List of file names with extension, without URL-encoding, without any URI paths. Example: ["Queen - Show must go on.mp3"]
  Stream<String> get playlistStream => _playlistStream;

  // functions
  /// Loads all data from the web server asynchronously. Should be called once.
  Future loadAll() async {
    final serverUri = Settings.instance.getServerUri();
    try {
      final response = await http.get(Uri.parse(serverUri));
      if (response.statusCode == 200) {
        final htmlDoc = parse(response.body);
        final elements = htmlDoc.getElementsByTagName("a");
        _playlist.clear();
        _playlist.addAll(elements.map((e) => e.text));
        _playlist.shuffle(_random);
        _playlistStream = Stream.periodic(const Duration(milliseconds: THROTTLING_MSEC), (i) => _playlist[i]).take(min(_playlist.length, MAX_PLAYLIST));
        FLog.info(text: "Loaded ${_playlist.length} songs from $serverUri; playlist: $_playlist");
      } else FLog.error(text: "Cannot load from $serverUri, response=${response.body}");
    } catch (e) {
      FLog.error(text: "Cannot parse uri: $serverUri ($e)");
    }
  }
}
