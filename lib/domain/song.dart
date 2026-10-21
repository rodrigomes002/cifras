class Song {
  const Song({
    this.id,
    required this.title,
    required this.artist,
    required this.key,
    required this.tempo,
    this.timeSignature = '4/4',
    this.sections = const [],
  });

  final int? id;
  final String title;
  final String artist;
  final String key;
  final int? tempo;
  final String timeSignature;
  final List<SongSection> sections;
}

class SongSection {
  const SongSection({
    this.id,
    required this.songId,
    required this.title,
    required this.measures,
    required this.position,
  });

  final int? id;
  final int songId;
  final String title;
  final List<String> measures;
  final int position;

  static List<String> parseMeasures(String input) => input
      .split('|')
      .map((measure) => measure.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((measure) => measure.isNotEmpty)
      .toList(growable: false);
}

class NewSong {
  const NewSong({
    required this.title,
    required this.artist,
    required this.key,
    required this.tempo,
    this.timeSignature = '4/4',
  });

  final String title;
  final String artist;
  final String key;
  final int? tempo;
  final String timeSignature;
}

class NewSection {
  const NewSection({required this.title, required this.measures});

  final String title;
  final List<String> measures;
}
