// ignore_for_file: curly_braces_in_flow_control_structures
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:tommyplayer/song.dart';
import 'package:tommyplayer/settings/settings.dart';
import 'package:tommyplayer/tommylogger.dart';

class ModelNetwork {
  Future<List<Song>> loadSongs() async {
    final settings = Settings.instance;
    final serverUri = settings.getServerUri();
    try {
      final response = await http.get(Uri.parse(serverUri));
      if (response.statusCode == 200) {
        final htmlDoc = parse(response.body);
        final elements = htmlDoc.getElementsByTagName("a");
        final list = elements.where((e) => _isSupported(e.text)).map((e) {
          final name = e.text;
          final uri = e.attributes['href'] ?? Uri.encodeFull(name);
          final score = settings.getStars(name);
          return Song(uri, e.text, score);
        }).toList();
        TommyLogger.logger.info("Loaded ${list.length} songs from $serverUri", 1000);
        return list;
      } else throw Exception("Error: status=${response.statusCode}; response=${response.body}");
    } catch (e) {
      TommyLogger.logger.error("Error loadAll(): $serverUri ($e)", 3000);
      return List.empty();
    }
  }

  Future<void> loadScores() async {
    final settings = Settings.instance;
    final filename = settings.getScoresFilename();
    final uri = "${settings.getServerUri()}/$filename";
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        var n = 0;
        response.body.split('\n').where((s) => s.isNotEmpty).forEach((line) {
          final lst = line.split("|");
          try {
            final song = lst.first;
            final stars = int.parse(lst[1]);
            settings.setStars(song, stars);
            n++;
          } catch (e) { TommyLogger.logger.error("Error: cannot handle line $n from scores: $lst, ($e)", 1000); }
        });
        TommyLogger.logger.info("Loaded $n scores from $filename", 1000);
      } else if (response.statusCode == 404) {
        TommyLogger.logger.warn("File '$filename' is not found on your server.\nUpload this file to music directory to keep scores!", 2000);
      } else throw Exception("Error: status=${response.statusCode}; response=${response.body}");
    } catch (e) {
      TommyLogger.logger.error("Error loadScores(): $uri ($e)", 3000);
    }
  }

  Future<void> uploadFile(String path) async {
    final settings = Settings.instance;
    final uri = "${settings.getServerUri()}/upload";
    final filename = settings.getScoresFilename();
    try {
      final request = http.MultipartRequest("POST", Uri.parse(uri));
      request.files.add(await http.MultipartFile.fromPath("files", path, filename: filename));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        TommyLogger.logger.info("Upload OK to $uri", 1000);
      } else throw Exception("Error: $response");
    } catch (e) {
      TommyLogger.logger.error("Error uploadFile($path): uri=$uri, filename=$filename ($e)", 3000);
    }
  }

  bool _isSupported(String filename) {
    const formats = {".mp3",".wav",".aac",".adts",".ac3",".aif",".aiff",".aifc",".caf",".mp4",".m4a",".snd",".au",".sd2"};
    return formats.any((e) => filename.endsWith(e));
  }
}
