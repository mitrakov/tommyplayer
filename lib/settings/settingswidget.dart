// ignore_for_file: use_key_in_widget_constructors
import 'package:flutter/material.dart';
import 'package:tommyplayer/settings/settings.dart';

class SettingsWidget extends StatelessWidget {
  final _serverUriCtrl = TextEditingController(text: Settings.instance.getServerUri());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tommy Player")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text("Hostname or\nIP-address:"),
                const SizedBox(width: 20),
                Expanded(
                  child: TextField(controller: _serverUriCtrl, onChanged: Settings.instance.setServerUri, decoration: const InputDecoration(border: OutlineInputBorder())),
                )
              ],
            )
          ]
        ),
      ),
    );
  }
}
