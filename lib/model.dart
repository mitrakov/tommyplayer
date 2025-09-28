import 'dart:io';
import 'dart:math';
import 'package:f_logs/f_logs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:tommyplayer/model_network.dart';
import 'package:tommyplayer/settings/settings.dart';
import 'package:tommyplayer/song.dart';

/// Main model class
class MyModel extends Model {
  static const THROTTLING_MSEC = 1000; // performance: sleep N msec between each feed to Player instance
  static const MAX_PLAYLIST = 400; // performance: load no more that N songs to Player instance

  // vals
  final ModelNetwork net = ModelNetwork();
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  final List<Song> _playlist = [];
  late final Stream<Song> playlistStream;

  /// Loads songs and scores from the server. Should be called once
  Future<void> loadAll() async {
    await net.loadScores();
    final list = await net.loadSongs();
    list.shuffle(_random);
    final sublist = list.take(MAX_PLAYLIST).toList();
    _playlist..clear()..addAll(sublist);
    playlistStream = Stream.periodic(const Duration(milliseconds: THROTTLING_MSEC), (i) => _playlist[i]).take(_playlist.length);
    FLog.info(text: "Loaded ${list.length} songs; used ${_playlist.length} of them");
  }

  Future writeToTempFileAsync(String content) async {
    final settings = Settings.instance;
    try {
      final filePath = '${(await getTemporaryDirectory()).path}/${settings.getScoresFilename()}';
      final file = File(filePath);
      final content = settings.getAppKeys().map((key) => "$key|${settings.getStars(key)}").join("\n");
      file.writeAsString(content); // TODO await?
    } catch (e) {
      FLog.error(text: "Error writing ${settings.getScoresFilename()} file: $e)");
    }
  }
}
