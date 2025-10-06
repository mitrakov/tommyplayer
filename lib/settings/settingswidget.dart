// ignore_for_file: use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:tommyplayer/settings/settings.dart';

class SettingsWidget extends StatelessWidget {
  final settings = Settings.local;
  final _serverUriCtrl  = TextEditingController(text: Settings.local.serverUri);
  final _scoresFileCtrl = TextEditingController(text: Settings.local.scoresFilename);
  final _minStarsCtrl   = TextEditingController(text: Settings.local.minStarsToPlay.toString());

  @override
  Widget build(BuildContext context) {
    const decor = InputDecoration(border: OutlineInputBorder());
    return Scaffold(
      appBar: AppBar(title: const Text("Tommy Player")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Hostname or IP-address:"),
                TextField(controller: _serverUriCtrl, onChanged: (s) => settings.serverUri = s, decoration: decor),
                const SizedBox(height: 20),
                const Text("Scores filename:"),
                TextField(controller: _scoresFileCtrl, onChanged: (s) => settings.scoresFilename = s, decoration: decor),
                const SizedBox(height: 20),
                const Text("Min stars to play 0-5 (0 = play all):"),
                TextField(
                  controller: _minStarsCtrl, onChanged: (s) => settings.minStarsToPlay = int.tryParse(s) ?? 0, decoration: decor
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
