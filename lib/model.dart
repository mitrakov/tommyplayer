import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:tommyplayer/model_network.dart';
import 'package:tommyplayer/settings/settings.dart';
import 'package:tommyplayer/song.dart';
import 'package:tommyplayer/tommylogger.dart';

/// Main model class
class MyModel extends Model {
  static const THROTTLING_MSEC = 1500; // performance: sleep N msec between each feed to Player instance (min 1000!)

  // vals
  final ModelNetwork net = ModelNetwork();
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  final List<Song> _playlist = [];
  late final Stream<Song> playlistStream;

  /// Loads songs and scores from the server. Should be called once
  Future<void> loadAll() async {
    await net.loadScores();
    final list = await net.loadSongs();
    final playAll = Settings.instance.getMinStarsToPlay() == 0;
    if (playAll && list.any((song) => song.score == 0)) {
      list.removeWhere((song) => song.score > 0); // play only unrated songs
    }
    list.shuffle(_random);
    _playlist..clear()..addAll(list);
    playlistStream = Stream.periodic(const Duration(milliseconds: THROTTLING_MSEC), (i) => _playlist[i]).take(_playlist.length);
    TommyLogger.logger.info("Will be added ${_playlist.length} songs", 1000);
  }

  Future<String?> writeScoreToTempFile() async {
    final settings = Settings.instance;
    final filename = settings.getScoresFilename();
    try {
      final filePath = "${(await getTemporaryDirectory()).path}/$filename";
      final content = settings.getAppKeys().map((key) => "$key|${settings.getStars(key)}").join("\n");
      await File(filePath).writeAsString(content);
      return filePath;
    } catch (e) {
      TommyLogger.logger.error("Error writing $filename: $e)", 3000);
      return null;
    }
  }
}
