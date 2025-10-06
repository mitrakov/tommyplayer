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
  static const THROTTLING_MSEC = 1800; // performance: sleep N msec between each feed to Player instance (min 1000!)
  static const MAX_PLAYLIST = 200; // performance: limit total count of songs

  // vals
  final ModelNetwork net = ModelNetwork();
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  late final Stream<Song> playlistStream;

  /// Loads songs and scores from the server. Should be called once
  Future<void> loadAll() async {
    await net.loadScores();
    final list = await net.loadSongs();
    final n = list.length;
    final newList = _filterSongs(list);
    newList.shuffle(_random);
    playlistStream = Stream.periodic(const Duration(milliseconds: THROTTLING_MSEC), (i) => newList[i]).take(newList.length);
    TommyLogger.logger.info("Will be added ${newList.length}/$n songs", 1000);
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

  List<Song> _filterSongs(List<Song> list) {
    final minStars = Settings.instance.getMinStarsToPlay();

    if (minStars > 0) {
      TommyLogger.logger.info("MinStars = $minStars, let's play only top songs", 1000);
      list.retainWhere((song) => song.score >= minStars);
    } else if (list.any((song) => song.score == 0)) { // if not set => I want to play unrated songs first
      TommyLogger.logger.info("There are unrated songs, let's play them first", 1000);
      list.retainWhere((song) => song.score == 0);
    } else {
      TommyLogger.logger.info("Radio mode", 1000);
      list.retainWhere((song) => _random.nextDouble() < (song.score / 5.0));
    }

    return list.take(MAX_PLAYLIST).toList();
  }
}
