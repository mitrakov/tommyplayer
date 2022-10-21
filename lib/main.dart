// ignore_for_file: avoid_print, use_key_in_widget_constructors, constant_identifier_names, curly_braces_in_flow_control_structures
import 'dart:math';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:tommyplayer/model.dart';

/// Starting point
void main() async {
  // allow "async" in main
  WidgetsFlutterBinding.ensureInitialized();

  // create all primary objects
  final model = MyModel();
  final player = AudioPlayer();
  final random = Random(DateTime.now().millisecondsSinceEpoch);

  // init model
  await model.loadAll();

  // init player
  final audioSource = ConcatenatingAudioSource(
    useLazyPreparation: true,
    shuffleOrder: DefaultShuffleOrder(random: random),
    children: model.playlist.map((String file) => AudioSource.uri(Uri.parse(Uri.encodeFull("${MyModel.url}/$file")), tag: file)).toList()
  );
  player.setAudioSource(audioSource);
  player.setLoopMode(LoopMode.all);
  player.setShuffleModeEnabled(true);

  // run!
  runApp(ScopedModel(model: model, child: MainApp(player)));
}

/// Main app widget
class MainApp extends StatefulWidget {
  static const double MARGIN = 25; // margin between icons
  static const double ICON_SIZE = 65;
  final AudioPlayer player;

  const MainApp(this.player);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool isPlaying = false;
  String currentSong = "";

  @override
  void initState() {
    // subscribe on the playbackEvent stream to get a new song name once playback finished
    super.initState();
    widget.player.playbackEventStream.listen((e) => updateCurrentSong());
  }

  /// Callback for PLAY and PAUSE buttons
  void onPlayButtonClick() {
    if (isPlaying) widget.player.pause(); else widget.player.play();
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  /// Updates current song name in "setState" manner
  void updateCurrentSong() {
    setState(() {
      final int index = widget.player.currentIndex ?? 0;
      currentSong = "${widget.player.audioSource?.sequence[index].tag}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Where is this title shown?",
      theme: ThemeData(primarySwatch: Colors.purple),
      home: ScopedModelDescendant<MyModel>(builder: (context, child, model) {
        return Scaffold(
          appBar: AppBar(title: const Text("Tommy's Player")),
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
                      onPressed: widget.player.seekToPrevious
                    ),
                    const SizedBox(width: MainApp.MARGIN),
                    IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_outlined : Icons.play_circle_outlined),
                      color: isPlaying ? Colors.deepOrange : Colors.green,
                      iconSize: MainApp.ICON_SIZE,
                      onPressed: onPlayButtonClick
                    ),
                    const SizedBox(width: MainApp.MARGIN),
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrowshape_turn_up_right_circle),
                      color: Colors.blue,
                      iconSize: MainApp.ICON_SIZE,
                      onPressed: widget.player.seekToNext
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
