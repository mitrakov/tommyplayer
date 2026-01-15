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
  final ModelNetwork net = ModelNetwork();
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);

  /// Loads songs and scores from the server. Should be called once
  Future<List<Song>> loadAll() async {
    await net.loadScores();
    final list = await net.loadSongs();
    return _filterSongs(list);
  }

  /// Writes score file (usually !scores.txt) in temp dir on the device
  Future<String?> writeScoreToTempFile() async {
    final settings = Settings.local;
    final filename = settings.scoresFilename;
    try {
      final filePath = "${(await getTemporaryDirectory()).path}/$filename";
      final content = settings.appKeys.map((key) => "$key|${settings.getStars(key)}").join("\n");
      await File(filePath).writeAsString(content);
      return filePath;
    } catch (e) {
      TommyLogger.logger.error("Error writing $filename: $e)", 3000);
      return null;
    }
  }

  List<Song> _filterSongs(List<Song> list) {
    final minStars = Settings.local.minStarsToPlay;
    final initListSize = list.length;

    if (minStars > 0) {
      TommyLogger.logger.info("MinStars = $minStars, let's play only top songs", 1000);
      list.retainWhere((song) => song.score >= minStars);
    } else if (list.any((song) => song.score == 0)) { // if ∃ at least 1 unrated song => I want to play unrated songs first
      TommyLogger.logger.info("There are unrated songs, let's play them first", 1000);
      list.retainWhere((song) => song.score == 0);
    } else {
      TommyLogger.logger.info("Radio mode", 1000);
      list.retainWhere((song) => _random.nextDouble() < (song.score / 5.0));
    }

    list.shuffle(_random);
    TommyLogger.logger.info("Will be added ${list.length}/$initListSize songs", 1000);
    return list;
  }
}
