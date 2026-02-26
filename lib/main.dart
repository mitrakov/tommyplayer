import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart';
import 'package:line_icons/line_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:tommyplayer/tommylogger.dart';
import 'package:tommyplayer/settings/settings.dart';
import 'package:tommyplayer/settings/settingswidget.dart';
import 'package:tommyplayer/model.dart';

// 1. allow insecure "http" in settings (iOS/MacOS: NSAllowsArbitraryLoads, Android: usesCleartextTraffic
// 2. there is a bug with ratings of files with cyrillic "й" and "ё" named in Windows; bug is not fixed (I've just renamed files)

/*
Build for iOS:
  bump version in pubspec.yaml
  flutter build ios
  xCode: Product -> Destination -> Any iOS Device (arm64)
  xCode: Product -> Archive -> Distribute App -> Release Testing
  rename and move *.ipa file to dist/

Build for Android:
  bump version in pubspec.yaml
  flutter build apk
  AndroidStudio: Build -> Generate Signed App Bundle or APK -> APK -> choose android/keystore.jks -> release
  rename and move *.apk file to dist/

Build for MacOS:
  bump version in pubspec.yaml
  flutter build macos
  xCode: Product -> Destination -> Any Mac (arm64, x86_64)
  xCode: Product -> Archive -> Distribute App -> Direct Distribution -> wait for 30-40 sec for notarization service to complete
  copy "*.app" to "_installer/macos/App"
  run _installer/macos/build-dmg.sh
  move *.dmg image to dist/
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // allow "async" in main
  await Settings.init();
  final model = MyModel();

  runApp(ScopedModel(model: model, child: MaterialApp(
    title: "Tommy Player",
    theme: ThemeData(primarySwatch: Colors.purple),
    home: MainApp(model)
  )));
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
  late final player = widget.player;
  late final model = widget.model;

  String currentSong = "";
  int _prevIndex = -1;           // to track down 'new song' events (don't use player.previousIndex, it's not reliable)

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

      // load and add songs
      const uuid = Uuid();
      final server = Settings.local.serverUri;
      final songs = await model.loadAll();
      player.setLoopMode(LoopMode.all);
      player.playbackEventStream.listen(_onPlaybackEvent);
      player.addAudioSources(songs.map((song) {
        final item = MediaItem(id: uuid.v4(), title: song.text, rating: Rating.newStarRating(RatingStyle.range5stars, song.score));
        return AudioSource.uri(Uri.parse("$server/${song.url}"), tag: item);
      }).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    TommyLogger.logger.init(context);
    final stars = Settings.local.getStars(currentSong);
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
                  icon: Icon(player.playing
                      ? Icons.pause_circle_outlined
                      : Icons.play_circle_outlined),
                  color: player.playing ? Colors.deepOrange : Colors.green,
                  iconSize: ICON_SIZE,
                  onPressed: _onPlayButtonClick,
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.arrowshape_turn_up_right_circle),
                  color: Colors.blue,
                  iconSize: ICON_SIZE,
                  onPressed: player.seekToNext,
                ),
              ],
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
      floatingActionButton: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: 30),
        FloatingActionButton.small(child: Icon(_getPlayModeIcon()), onPressed: _changePlayMode),
      ]),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
    );
  }

  /// callback for Playback Events from AudioPlayer
  void _onPlaybackEvent(PlaybackEvent e) {
    final idx = e.currentIndex;
    if (idx != null && idx != _prevIndex && idx < player.audioSources.length && e.processingState == ProcessingState.ready) {
      print("Playlist index = $idx");
      _prevIndex = idx;

      final MediaItem item = player.audioSources[idx].sequence.first.tag;
      final allSongsRated = !model.scoreExists(score: 0);
      if (allSongsRated) {
        final stars = item.rating?.getStarRating() ?? 0;
        final minStars = Settings.local.minStarsToPlay;
        final playOnlyTop = minStars > 0 && model.scoreExists(minScore: minStars);
        final play = playOnlyTop ? stars >= minStars : model.random.nextDouble() < stars / 5.0;
        if (!play) {
          print("Skipping to next");
          Future.delayed(Duration.zero, () => player.seekToNext());
        }
      }
      setState(() {
        currentSong = item.title;
      });
    }
  }

  /// PLAY and PAUSE buttons
  void _onPlayButtonClick() {
    setState(() {
      if (player.playing)
        player.pause();
      else player.play();
    });
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
      final filepath = await model.writeScoreToTempFile();
      if (filepath != null) {
        await SharePlus.instance.share(ShareParams(title: 'Save file "$fileName"?', files: [XFile(filepath)]));
      }
    } catch (e) { TommyLogger.logger.error("Error sharing file $fileName: $e", 3000); }
  }

  /// returns dice Icon depending on Settings.minStarsToPlay
  IconData _getPlayModeIcon() {
    switch (Settings.local.minStarsToPlay) {
      case 1:  return LineIcons.diceOne;
      case 2:  return LineIcons.diceTwo;
      case 3:  return LineIcons.diceThree;
      case 4:  return LineIcons.diceFour;
      case 5:  return LineIcons.diceFive;
      default: return LineIcons.diceD6;
    }
  }

  /// handler for "Dice" icon click
  void _changePlayMode() async {
    if (model.scoreExists(score: 0))
      TommyLogger.logger.warn("You can set min stars once all songs are rated", 2000);
    else setState(() {
      final newMinStars = (Settings.local.minStarsToPlay + 1) % 6;
      TommyLogger.logger.info("Setting min stars to $newMinStars", 1000);
      Settings.local.setMinStarsToPlay(newMinStars);
    });
  }
}
