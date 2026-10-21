const _pitchClasses = {
  'C': 0,
  'C#': 1,
  'Db': 1,
  'D': 2,
  'D#': 3,
  'Eb': 3,
  'E': 4,
  'Fb': 4,
  'E#': 5,
  'F': 5,
  'F#': 6,
  'Gb': 6,
  'G': 7,
  'G#': 8,
  'Ab': 8,
  'A': 9,
  'A#': 10,
  'Bb': 10,
  'B': 11,
  'Cb': 11,
};

const _pitchNames = [
  'C',
  'C#',
  'D',
  'Eb',
  'E',
  'F',
  'F#',
  'G',
  'Ab',
  'A',
  'Bb',
  'B',
];

const _sharpPitchNames = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

int? _pitchClass(String note) => _pitchClasses[note];

({String root, bool minor})? _parseKey(String key) {
  final match = RegExp(
    r'^([A-Ga-g][#b]?)(?:\s*(m|min|minor|menor|maj|major|maior))?$',
    caseSensitive: false,
  ).firstMatch(key.trim());
  if (match == null) return null;

  final root = match.group(1)!;
  final normalizedRoot = '${root[0].toUpperCase()}${root.substring(1)}';
  if (_pitchClass(normalizedRoot) == null) return null;
  final suffix = match.group(2)?.toLowerCase();
  return (
    root: normalizedRoot,
    minor: suffix == 'm' ||
        suffix == 'min' ||
        suffix == 'minor' ||
        suffix == 'menor',
  );
}

String? normalizeSongKey(String key) {
  final parsed = _parseKey(key);
  if (parsed == null) return null;
  return '${parsed.root}${parsed.minor ? 'm' : ''}';
}

String? shiftSongKey(String key, int semitones) {
  final parsed = _parseKey(key);
  if (parsed == null) return null;
  final pitch = _pitchClass(parsed.root)!;
  final shiftedPitch = (pitch + semitones) % 12;
  final normalizedPitch = (shiftedPitch + 12) % 12;
  return '${_sharpPitchNames[normalizedPitch]}${parsed.minor ? 'm' : ''}';
}

int? songKeyInterval(String fromKey, String toKey) {
  final from = _parseKey(fromKey);
  final to = _parseKey(toKey);
  final fromPitch = from == null ? null : _pitchClass(from.root);
  final toPitch = to == null ? null : _pitchClass(to.root);
  if (fromPitch == null || toPitch == null) return null;
  return (toPitch - fromPitch) % 12;
}

String transposeChord(String chord, int semitones) {
  final match = RegExp(
    r'^([A-Ga-g][#b]?)([^/]*)(?:/([A-Ga-g][#b]?))?$',
  ).firstMatch(chord);
  if (match == null) {
    throw FormatException('Não foi possível transpor o acorde "$chord".');
  }

  String transposeNote(String note) {
    final normalized = '${note[0].toUpperCase()}${note.substring(1)}';
    final pitch = _pitchClass(normalized);
    if (pitch == null) {
      throw FormatException('Nota inválida no acorde "$chord".');
    }
    return _pitchNames[(pitch + semitones) % 12];
  }

  final bass = match.group(3);
  return '${transposeNote(match.group(1)!)}${match.group(2)!}'
      '${bass == null ? '' : '/${transposeNote(bass)}'}';
}

List<String> transposeMeasures(List<String> measures, int semitones) =>
    measures
        .map(
          (measure) => measure
              .split(RegExp(r'\s+'))
              .map((chord) => transposeChord(chord, semitones))
              .join(' '),
        )
        .toList(growable: false);
