import 'dart:convert';

import 'song.dart';

const _backupFormat = 'cifras';
const _backupVersion = 1;

String encodeSongBackup(List<Song> songs) =>
    const JsonEncoder.withIndent('  ').convert({
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
                  'position': section.position,
                  'timeSignature': section.timeSignature,
                },
            ],
          },
      ],
    });

List<Song> decodeSongBackup(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! Map<String, dynamic> ||
      decoded['format'] != _backupFormat ||
      decoded['version'] != _backupVersion ||
      decoded['songs'] is! List) {
    throw const FormatException(
      'O arquivo não é um backup JSON válido do Cifras.',
    );
  }

  final songs = decoded['songs'] as List;
  return [
    for (var index = 0; index < songs.length; index++)
      _decodeSong(songs[index], index),
  ];
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
  return SongSection(
    songId: 0,
    title: _string(map['title'], '$path.title'),
    measures: [
      for (var index = 0; index < measures.length; index++)
        _string(measures[index], '$path.measures[$index]'),
    ],
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

String _string(Object? value, String path) {
  if (value is String) return value;
  throw FormatException('$path deve ser um texto.');
}

int _int(Object? value, String path) {
  if (value is int) return value;
  throw FormatException('$path deve ser um número inteiro.');
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
