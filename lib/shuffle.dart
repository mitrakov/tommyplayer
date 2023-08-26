import 'package:just_audio/just_audio.dart';

/*
  This class is to avoid error:
    [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: RangeError (index): Invalid value: Not in inclusive range 0..80: 118
    #0      List.[] (dart:core-patch/growable_array.dart:264:36)
    #1      AudioSourceExtension.shuffleIndices (package:just_audio_background/just_audio_background.dart:807:40)
    #2      _PlayerAudioHandler._updateShuffleIndices (package:just_audio_background/just_audio_background.dart:492:32)
    #3      _PlayerAudioHandler.customConcatenatingInsertAll (package:just_audio_background/just_audio_background.dart:450:5)
    #4      _JustAudioPlayer.concatenatingInsertAll (package:just_audio_background/just_audio_background.dart:288:27)
    #5      ConcatenatingAudioSource.add (package:just_audio/just_audio.dart:2415:40)
    <asynchronous suspension>

    [ERROR:flutter/runtime/dart_vm_initializer.cc(41)] Unhandled Exception: RangeError (index): Invalid value: Not in inclusive range 0..81: 118
    #0      List.[] (dart:core-patch/growable_array.dart:264:36)
    #1      AudioSourceExtension.shuffleIndices (package:just_audio_background/just_audio_background.dart:807:40)
    #2      _PlayerAudioHandler._updateShuffleIndices (package:just_audio_background/just_audio_background.dart:492:32)
    #3      _PlayerAudioHandler.customConcatenatingInsertAll (package:just_audio_background/just_audio_background.dart:450:5)
    #4      _JustAudioPlayer.concatenatingInsertAll (package:just_audio_background/just_audio_background.dart:288:27)
    #5      ConcatenatingAudioSource.add (package:just_audio/just_audio.dart:2415:40)
    <asynchronous suspension>
 */
class NoShuffleOrder extends ShuffleOrder {
  @override
  List<int> get indices => [];

  @override
  void clear() {}

  @override
  void insert(int index, int count) {}

  @override
  void removeRange(int start, int end) {}

  @override
  void shuffle({int? initialIndex}) {}
}
