// ignore_for_file: use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:tommyplayer/settings/settings.dart';

class SettingsWidget extends StatefulWidget {
  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  // widget MUST be stateful! (to avoid bugs with cursor in TextFields)
  final _serverUriCtrl  = TextEditingController(text: Settings.local.serverUri);
  final _scoresFileCtrl = TextEditingController(text: Settings.local.scoresFilename);
  final _minStarsCtrl   = TextEditingController(text: Settings.local.minStarsToPlay.toString());

  @override
  Widget build(BuildContext context) {
    const d = InputDecoration(border: OutlineInputBorder());
    final settings = Settings.local;
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
                TextField(controller: _serverUriCtrl, onChanged: (s) => settings.serverUri = s, decoration: d),
                const SizedBox(height: 20),
                const Text("Scores filename:"),
                TextField(controller: _scoresFileCtrl, onChanged: (s) => settings.scoresFilename = s, decoration: d),
                const SizedBox(height: 20),
                const Text("Min stars to play 0-5 (0 = play all):"),
                TextField(controller: _minStarsCtrl, onChanged: (s) => settings.minStarsToPlay = int.tryParse(s) ?? 0, decoration: d),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverUriCtrl.dispose();
    _scoresFileCtrl.dispose();
    _minStarsCtrl.dispose();
    super.dispose();
  }
}
