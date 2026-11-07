import 'dart:convert';

import 'song.dart';

const _backupFormat = 'cifras';
const _backupVersion = 3;

class SongBackup {
  const SongBackup({required this.songs, this.customChords, this.chordShapes});

  final List<Song> songs;
  final List<String>? customChords;
  final Map<String, List<GuitarChordShape>>? chordShapes;

  bool get includesChordDictionary =>
      customChords != null && chordShapes != null;
}

String encodeSongBackup(
  List<Song> songs, {
  required List<String> customChords,
  required Map<String, List<GuitarChordShape>> chordShapes,
}) => const JsonEncoder.withIndent('  ').convert({
  'format': _backupFormat,
  'version': _backupVersion,
  'songs': [
    for (final song in songs)
      {
        'title': song.title,
        'artist': song.artist,
        'key': song.key,
        'tempo': song.tempo,
        'timeSignature': song.timeSignature,
        'isFavorite': song.isFavorite,
        'sections': [
          for (final section in song.sections)
            {
              'title': section.title,
              'measures': section.measures,
              'repetitions': section.repetitions,
              'measureRepetitions': [
                for (var index = 0; index < section.measures.length; index++)
                  section.repetitionsForMeasure(index),
              ],
              'position': section.position,
              'timeSignature': section.timeSignature,
            },
        ],
      },
  ],
  'customChords': customChords,
  'chordShapes': [
    for (final entry in chordShapes.entries)
      {
        'chord': entry.key,
        'shapes': [
          for (final shape in entry.value)
            {
              'frets': shape.frets,
              'fingers': shape.fingers,
              'baseFret': shape.baseFret,
              'barreStart': shape.barreStart,
              'barreEnd': shape.barreEnd,
            },
        ],
      },
  ],
});

SongBackup decodeSongBackup(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic> ||
      decoded['format'] != _backupFormat ||
      decoded['version'] is! int ||
      ![1, 2, _backupVersion].contains(decoded['version']) ||
      decoded['songs'] is! List) {
    throw const FormatException(
      'O arquivo não é um backup JSON válido do Cifras.',
    );
  }

  final songs = decoded['songs'] as List;
  final version = decoded['version'] as int;
  if (version == 1) {
    return SongBackup(
      songs: [
        for (var index = 0; index < songs.length; index++)
          _decodeSong(songs[index], index),
      ],
    );
  }

  final customChords = _asList(decoded['customChords'], 'customChords');
  final chordShapes = _asList(decoded['chordShapes'], 'chordShapes');
  return SongBackup(
    songs: [
      for (var index = 0; index < songs.length; index++)
        _decodeSong(songs[index], index),
    ],
    customChords: [
      for (var index = 0; index < customChords.length; index++)
        _string(customChords[index], 'customChords[$index]'),
    ],
    chordShapes: {
      for (var index = 0; index < chordShapes.length; index++)
        ..._decodeChordShapes(chordShapes[index], index),
    },
  );
}

Map<String, List<GuitarChordShape>> _decodeChordShapes(
  Object? value,
  int index,
) {
  final path = 'chordShapes[$index]';
  final map = _asMap(value, path);
  final chord = _string(map['chord'], '$path.chord');
  final shapes = _asList(map['shapes'], '$path.shapes');
  return {
    chord: [
      for (var shapeIndex = 0; shapeIndex < shapes.length; shapeIndex++)
        _decodeChordShape(shapes[shapeIndex], '$path.shapes[$shapeIndex]'),
    ],
  };
}

GuitarChordShape _decodeChordShape(Object? value, String path) {
  final map = _asMap(value, path);
  return GuitarChordShape(
    frets: _intList(map['frets'], '$path.frets'),
    fingers: _intList(map['fingers'], '$path.fingers'),
    baseFret: _int(map['baseFret'], '$path.baseFret'),
    barreStart: _nullableInt(map['barreStart'], '$path.barreStart'),
    barreEnd: _nullableInt(map['barreEnd'], '$path.barreEnd'),
  );
}

Song _decodeSong(Object? value, int index) {
  final path = 'songs[$index]';
  final map = _asMap(value, path);
  final sections = _asList(map['sections'], '$path.sections');
  return Song(
    title: _string(map['title'], '$path.title'),
    artist: _string(map['artist'], '$path.artist'),
    key: _string(map['key'], '$path.key'),
    tempo: _nullableInt(map['tempo'], '$path.tempo'),
    timeSignature: _string(map['timeSignature'], '$path.timeSignature'),
    isFavorite: _bool(map['isFavorite'], '$path.isFavorite'),
    sections: [
      for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++)
        _decodeSection(sections[sectionIndex], index, sectionIndex),
    ],
  );
}

SongSection _decodeSection(Object? value, int songIndex, int sectionIndex) {
  final path = 'songs[$songIndex].sections[$sectionIndex]';
  final map = _asMap(value, path);
  final measures = _asList(map['measures'], '$path.measures');
  final measureRepetitions = map.containsKey('measureRepetitions')
      ? _asList(map['measureRepetitions'], '$path.measureRepetitions')
      : List<Object?>.filled(measures.length, 1);
  final repetitions = map.containsKey('repetitions')
      ? _positiveInt(map['repetitions'], '$path.repetitions')
      : 1;
  if (measureRepetitions.length != measures.length) {
    throw FormatException(
      '$path.measureRepetitions deve ter o mesmo tamanho de measures.',
    );
  }
  return SongSection(
    songId: 0,
    title: _string(map['title'], '$path.title'),
    measures: [
      for (var index = 0; index < measures.length; index++)
        _string(measures[index], '$path.measures[$index]'),
    ],
    measureRepetitions: [
      for (var index = 0; index < measureRepetitions.length; index++)
        _positiveInt(
          measureRepetitions[index],
          '$path.measureRepetitions[$index]',
        ),
    ],
    repetitions: repetitions,
    position: _int(map['position'], '$path.position'),
    timeSignature: _string(map['timeSignature'], '$path.timeSignature'),
  );
}

Map<String, dynamic> _asMap(Object? value, String path) {
  if (value is Map<String, dynamic>) return value;
  throw FormatException('$path deve ser um objeto JSON.');
}

List<Object?> _asList(Object? value, String path) {
  if (value is List<Object?>) return value;
  throw FormatException('$path deve ser uma lista JSON.');
}

List<int> _intList(Object? value, String path) {
  final list = _asList(value, path);
  return [
    for (var index = 0; index < list.length; index++)
      _int(list[index], '$path[$index]'),
  ];
}

String _string(Object? value, String path) {
  if (value is String) return value;
  throw FormatException('$path deve ser um texto.');
}

int _int(Object? value, String path) {
  if (value is int) return value;
  throw FormatException('$path deve ser um número inteiro.');
}

int _positiveInt(Object? value, String path) {
  final result = _int(value, path);
  if (result > 0) return result;
  throw FormatException('$path deve ser um número inteiro positivo.');
}

int? _nullableInt(Object? value, String path) {
  if (value == null) return null;
  if (value is int) return value;
  throw FormatException('$path deve ser um número inteiro ou nulo.');
}

bool _bool(Object? value, String path) {
  if (value is bool) return value;
  throw FormatException('$path deve ser verdadeiro ou falso.');
}
