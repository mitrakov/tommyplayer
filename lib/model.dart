// ignore_for_file: curly_braces_in_flow_control_structures, avoid_print
import 'dart:math';
import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

/// Main model class
class MyModel extends Model {
  // vals
  static const String url = "http://mitrakoff.com:2000/music";  // allow insecure "http" in settings!
  final Random _random = Random(DateTime.now().millisecondsSinceEpoch);
  final List<String> _playlist = [];
  late Stream<String> _playlistStream;

  // getters
  /// List of file names with extension, without URL-encoding, without any URI paths. Example: ["Queen - Show must go on.mp3"]
  Stream<String> get playlistStream => _playlistStream;

  // functions
  /// Loads all data from the web server asynchronously. Should be called once.
  Future loadAll() async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final htmlDoc = parse(response.body);
      final elements = htmlDoc.getElementsByTagName("a");
      _playlist.clear();
      _playlist.addAll(elements.map((e) => e.text));
      _playlist.shuffle(_random);
      _playlistStream = Stream.periodic(const Duration(milliseconds: 500), (i) => _playlist[i]).take(_playlist.length);
      print("Loaded ${_playlist.length} songs; playlist: $_playlist");
    } else throw Exception("Cannot load from $url");
  }
}
