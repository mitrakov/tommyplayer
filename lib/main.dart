import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:tommyplayer/tommylogger.dart';
import 'package:tommyplayer/settings/settings.dart';
import 'package:tommyplayer/settings/settingswidget.dart';
import 'package:tommyplayer/model.dart';
import 'package:tommyplayer/shuffle.dart';

// 1. allow insecure "http" in settings (iOS/MacOS: NSAllowsArbitraryLoads, Android: usesCleartextTraffic (now deprecated, check)
// 2. there is a bug with ratings of files with cyrillic "й" and "ё" named in Windows; bug is not fixed (I've just renamed files)

/*
Build for iOS:
  bump version in pubspec.yaml
  flutter build ios
  xCode: Product -> Destination -> Any iOS Device (arm64)
  xCode: Product -> Archive -> Distribute App -> Release Testing
  rename and move *.ipa file to _dist

Build for MacOS:
  bump version in pubspec.yaml
  flutter build macos
  xCode: Product -> Destination -> Any Mac (arm64, x86_64)
  xCode: Product -> Archive -> Distribute App -> Direct Distribution -> wait for 30-40 sec for notarization service to complete
  copy "*.app" to "_installer/macos/App"
  run _installer/macos/build-dmg.sh
  move *.dmg image to _dist/
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // allow "async" in main
  await Settings.init();
  final model = MyModel();

  runApp(ScopedModel(model: model, child: MainApp(model)));
}

/// Main app widget
class MainApp extends StatefulWidget {
  final player = AudioPlayer();
  final MyModel model;

  MainApp(this.model);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  static const double MARGIN = 13; // margin between icons
  static const double ICON_SIZE_SMALL = 40;

  String currentSong = "";
  double get ICON_SIZE => MediaQuery.of(context).orientation == Orientation.portrait ? 100 : 105;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // init background playback
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.mitrakoff.self.tommyplayer.channel',
        androidNotificationChannelName: 'Audio playback',
        androidNotificationOngoing: true,
      );

      // init model
      await widget.model.loadAll();

      // player setup
      // set "useLazyPreparation" to "true" to load as late as possible
      // set "children" to [] to avoid loading tracks all-at-once!
      final audioSource = ConcatenatingAudioSource(useLazyPreparation: true, children: [], shuffleOrder: NoShuffleOrder());
      widget.player.setAudioSource(audioSource, preload: false); // set preload to "false" to delay immediate loading
      widget.player.setLoopMode(LoopMode.all);
      widget.player.playbackEventStream.listen((e) => _updateCurrentSong()); // to get a new song name once playback finished

      // async loading
      const uuid = Uuid();
      final server = Settings.local.serverUri;
      widget.model.playlistStream.listen((song) {
        // "audioSource.add" is quite heady and must be throttled!
        audioSource.add(AudioSource.uri(Uri.parse("$server/${song.url}"), tag: MediaItem(id: uuid.v4(), title: song.text)));
      });

      TommyLogger.logger.info("TommyPlayer INIT done. Enjoy!", 1000);
    });
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
  void _setLike(int like) {
    Settings.local.setStars(currentSong, like);
    setState(() {}); // to redraw the stars
  }

  /// Calls ShareWith dialog to upload a "!scores.txt" file
  void _shareScoreFile() async {
    final fileName = Settings.local.scoresFilename;
    try {
      final filepath = await widget.model.writeScoreToTempFile();
      if (filepath != null) {
        await Share.shareXFiles([XFile(filepath)], subject: 'Save file "$fileName"?');
      }
    } catch (e) {
      TommyLogger.logger.error("Error sharing file $fileName: $e", 3000);
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    return MaterialApp(
      title: "Tommy Player",
      theme: ThemeData(primarySwatch: Colors.purple),
      home: ScopedModelDescendant<MyModel>(builder: (context, child, model) { // TODO do we need this?
        final stars = Settings.local.getStars(currentSong);
        TommyLogger.logger.init(context);
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text("Tommy Player"),
            actions: [
              IconButton(
                icon: const Icon(CupertinoIcons.gear_big),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsWidget()))
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.info_circle),
                onPressed: () => TommyLogger.logger.info(Settings.local.version, 2000),
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.share_up),
                onPressed: _shareScoreFile,
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: MARGIN,
              children: [
                Text(currentSong, textAlign: TextAlign.center, style: const TextStyle(fontSize: 19)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: MARGIN,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrowshape_turn_up_left_circle),
                      color: Colors.blue,
                      iconSize: ICON_SIZE,
                      onPressed: player.seekToPrevious,
                    ),
                    IconButton(
                      icon: Icon(player.playing ? Icons.pause_circle_outlined : Icons.play_circle_outlined),
                      color: player.playing ? Colors.deepOrange : Colors.green,
                      iconSize: ICON_SIZE,
                      onPressed: _onPlayButtonClick,
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.arrowshape_turn_up_right_circle),
                      color: Colors.blue,
                      iconSize: ICON_SIZE,
                      onPressed: player.seekToNext,
                    )
                  ]
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: stars >= 1 ? Colors.orange : Colors.grey[400],
                      iconSize: ICON_SIZE_SMALL,
                      onPressed: () => _setLike(1),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: stars >= 2 ? Colors.orange : Colors.grey[400],
                      iconSize: ICON_SIZE_SMALL,
                      onPressed: () => _setLike(2),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: stars >= 3 ? Colors.orange : Colors.grey[400],
                      iconSize: ICON_SIZE_SMALL,
                      onPressed: () => _setLike(3),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: stars >= 4 ? Colors.orange : Colors.grey[400],
                      iconSize: ICON_SIZE_SMALL,
                      onPressed: () => _setLike(4),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.star_fill),
                      color: stars >= 5 ? Colors.orange : Colors.grey[400],
                      iconSize: ICON_SIZE_SMALL,
                      onPressed: () => _setLike(5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
