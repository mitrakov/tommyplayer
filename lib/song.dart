class Song {
  String url;
  String text;
  int score;
  Song(this.url, this.text, this.score);

  @override
  String toString() => 'Song{score: $score, text: $text, url: $url}';
}
