// ignore_for_file: avoid_print, use_key_in_widget_constructors, constant_identifier_names, curly_braces_in_flow_control_structures
import 'dart:math';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:tommyplayer/settings/settings.dart';
import 'package:tommyplayer/settings/settingswidget.dart';
import 'package:tommyplayer/model.dart';
import 'package:tommyplayer/shuffle.dart';

// allow insecure "http" in settings!
void main() async {
  // allow "async" in main
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.init();

  // obtain SharedPreferences
  final settings = await SharedPreferences.getInstance();

  // init background playback
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.mitrakov.self.player.channel',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // create all primary objects
  const uuid = Uuid();
  final model = MyModel();
  final player = AudioPlayer();

  // init model
  await model.loadAll();

  // init player
  // set "useLazyPreparation" to "true" to load as late as possible
  // set "children" to [] to avoid loading tracks all-at-once!
  final audioSource = ConcatenatingAudioSource(useLazyPreparation: true, children: [], shuffleOrder: NoShuffleOrder());
  player.setAudioSource(audioSource, preload: false); // set preload to "false" to delay immediate loading
  player.setLoopMode(LoopMode.all);

  // async loading
  final random = Random(DateTime.now().millisecondsSinceEpoch);
  model.playlistStream.listen((song) {
    final r = random.nextInt(5) + 1; // 1, 2, 3, 4, 5
    final like = settings.getInt(song) ?? 999; // default is 999, in order to include a song to the playlist and ask user to "like" it
    if (r <= like) {
      audioSource.add(AudioSource.uri(Uri.parse(Uri.encodeFull("${Settings.getServerUri()}/$song")), tag: MediaItem(id: uuid.v4(), title: song)));
    }
  });

  // run!
  runApp(ScopedModel(model: model, child: MainApp(player, settings)));
}

/// Main app widget
class MainApp extends StatefulWidget {
  static const double MARGIN = 25; // margin between icons
  static const double ICON_SIZE = 65;
  static const double ICON_SIZE_SMALL = 30;
  final AudioPlayer player;
  final SharedPreferences settings;

  const MainApp(this.player, this.settings);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String currentSong = "";

  @override
  void initState() {
    // subscribe on the playbackEvent stream to get a new song name once playback finished
    super.initState();
    widget.player.playbackEventStream.listen((e) => _updateCurrentSong());
  }

  /// Callback for PLAY and PAUSE buttons
  void _onPlayButtonClick() {
    if (widget.player.playing) widget.player.pause();
    else widget.player.play();
  }

  /// Updates current song name in "setState" manner
  void _updateCurrentSong() {
    final int? index = widget.player.currentIndex;
    final List<IndexedAudioSource> seq = widget.player.audioSource?.sequence ?? [];
    if (index != null && seq.isNotEmpty) {
      setState(() {
        currentSong = "${seq[index].tag.title}";
      });
    }
  }

  /// Saves a user's "like" for a current song to Shared Preferences
  void _setLike(int like) async {
    await widget.settings.setInt(currentSong, like);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    final settings = widget.settings;
    return MaterialApp(
      title: "Tommy Player",
      theme: ThemeData(primarySwatch: Colors.purple),
      home: ScopedModelDescendant<MyModel>(builder: (context, child, model) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Tommy Player"),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.gear_big),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsWidget()));
                }
              )
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(currentSong, style: const TextStyle(fontSize: 19)),
                const SizedBox(height: MainApp.MARGIN),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrowshape_turn_up_left_circle),
                      color: Colors.blue,
                      iconSize: MainApp.ICON_SIZE,
                      onPressed: player.seekToPrevious
                    ),
                    const SizedBox(width: MainApp.MARGIN),
                    IconButton(
                      icon: Icon(player.playing ? Icons.pause_circle_outlined : Icons.play_circle_outlined),
                      color: player.playing ? Colors.deepOrange : Colors.green,
                      iconSize: MainApp.ICON_SIZE,
                      onPressed: _onPlayButtonClick
                    ),
                    const SizedBox(width: MainApp.MARGIN),
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrowshape_turn_up_right_circle),
                      color: Colors.blue,
                      iconSize: MainApp.ICON_SIZE,
                      onPressed: player.seekToNext
                    )
                  ]
                ),
                const SizedBox(height: MainApp.MARGIN),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: (settings.getInt(currentSong) ?? 0) >= 1 ? Colors.red : Colors.grey,
                      iconSize: MainApp.ICON_SIZE_SMALL,
                      onPressed: () => _setLike(1)
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: (settings.getInt(currentSong) ?? 0) >= 2 ? Colors.orange : Colors.grey,
                      iconSize: MainApp.ICON_SIZE_SMALL,
                      onPressed: () => _setLike(2)
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: (settings.getInt(currentSong) ?? 0) >= 3 ? Colors.yellow : Colors.grey,
                      iconSize: MainApp.ICON_SIZE_SMALL,
                      onPressed: () => _setLike(3)
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: (settings.getInt(currentSong) ?? 0) >= 4 ? Colors.cyan : Colors.grey,
                      iconSize: MainApp.ICON_SIZE_SMALL,
                      onPressed: () => _setLike(4)
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: (settings.getInt(currentSong) ?? 0) >= 5 ? Colors.green : Colors.grey,
                      iconSize: MainApp.ICON_SIZE_SMALL,
                      onPressed: () => _setLike(5)
                    )
                  ]
                )
              ]
            )
          )
        );
      })
    );
  }
}
