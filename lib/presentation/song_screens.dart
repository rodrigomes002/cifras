import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../domain/music_transposition.dart';
import '../domain/song_backup.dart';
import '../domain/song.dart';
import '../theme/app_theme.dart';
import 'cifras_logo.dart';
import 'song_library_view_model.dart';

const _sectionNames = [
  'Intro',
  'Verso',
  'Pré-refrão',
  'Refrão',
  'Ponte',
  'Solo',
  'Final',
];

const _timeSignatures = ['2/4', '3/4', '4/4', '5/4', '6/8', '7/8', '12/8'];

const _chordRoots = [
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

const _chordQualities = {
  'Maior': '',
  'Menor': 'm',
  'Sétima': '7',
  'Maior com sétima': 'maj7',
  'Menor com sétima': 'm7',
  'Suspenso': 'sus4',
  'Diminuto': 'dim',
};

enum _ChordInstrument { guitar, keyboard }

enum _LibraryBackupAction { export, import }

enum _CagedShape { c, a, g, e, d }

const _chordPitchNames = [
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

const _chordPitchClasses = {
  'C': 0,
  'C#': 1,
  'Db': 1,
  'D': 2,
  'D#': 3,
  'Eb': 3,
  'E': 4,
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
};

class _GuitarShapeTemplate {
  const _GuitarShapeTemplate({
    required this.quality,
    required this.rootString,
    required this.frets,
    required this.openFingers,
    required this.movableFingers,
    this.barreStrings,
  });

  final String quality;
  final int rootString;
  final List<int> frets;
  final List<int> openFingers;
  final List<int> movableFingers;
  final (int, int)? barreStrings;
}

class _GuitarChordShape {
  const _GuitarChordShape({
    required this.frets,
    required this.fingers,
    required this.baseFret,
    required this.barreStrings,
  });

  final List<int> frets;
  final List<int> fingers;
  final int baseFret;
  final (int, int)? barreStrings;
}

class _CagedShapeTemplate {
  const _CagedShapeTemplate({
    required this.shape,
    required this.quality,
    required this.rootString,
    required this.rootFret,
    required this.frets,
    required this.openFingers,
    required this.movableFingers,
    this.barreStrings,
  });

  final _CagedShape shape;
  final String quality;
  final int rootString;
  final int rootFret;
  final List<int> frets;
  final List<int> openFingers;
  final List<int> movableFingers;
  final (int, int)? barreStrings;
}

const _guitarStrings = [
  (name: 'E', pitch: 4),
  (name: 'A', pitch: 9),
  (name: 'D', pitch: 2),
  (name: 'G', pitch: 7),
  (name: 'B', pitch: 11),
  (name: 'e', pitch: 4),
];

const _cagedShapeTemplates = [
  _CagedShapeTemplate(
    shape: _CagedShape.c,
    quality: '',
    rootString: 1,
    rootFret: 3,
    frets: [-1, 3, 2, 0, 1, 0],
    openFingers: [0, 3, 2, 0, 1, 0],
    movableFingers: [0, 1, 3, 0, 2, 1],
    barreStrings: (1, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.c,
    quality: 'm',
    rootString: 1,
    rootFret: 3,
    frets: [-1, 3, 5, 5, 4, 3],
    openFingers: [0, 1, 3, 4, 2, 1],
    movableFingers: [0, 1, 3, 4, 2, 1],
    barreStrings: (1, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.a,
    quality: '',
    rootString: 1,
    rootFret: 0,
    frets: [-1, 0, 2, 2, 2, 0],
    openFingers: [0, 0, 2, 3, 4, 0],
    movableFingers: [0, 1, 3, 3, 3, 1],
    barreStrings: (1, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.a,
    quality: 'm',
    rootString: 1,
    rootFret: 0,
    frets: [-1, 0, 2, 2, 1, 0],
    openFingers: [0, 0, 2, 3, 1, 0],
    movableFingers: [0, 1, 3, 3, 2, 1],
    barreStrings: (1, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.g,
    quality: '',
    rootString: 0,
    rootFret: 3,
    frets: [3, 2, 0, 0, 0, 3],
    openFingers: [2, 1, 0, 0, 0, 3],
    movableFingers: [2, 1, 1, 1, 1, 3],
    barreStrings: (2, 4),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.g,
    quality: 'm',
    rootString: 0,
    rootFret: 3,
    frets: [3, 5, 5, 3, 3, 3],
    openFingers: [1, 3, 4, 1, 1, 1],
    movableFingers: [1, 3, 4, 1, 1, 1],
    barreStrings: (0, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.e,
    quality: '',
    rootString: 0,
    rootFret: 0,
    frets: [0, 2, 2, 1, 0, 0],
    openFingers: [0, 2, 3, 1, 0, 0],
    movableFingers: [1, 3, 4, 2, 1, 1],
    barreStrings: (0, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.e,
    quality: 'm',
    rootString: 0,
    rootFret: 0,
    frets: [0, 2, 2, 0, 0, 0],
    openFingers: [0, 2, 3, 0, 0, 0],
    movableFingers: [1, 3, 4, 1, 1, 1],
    barreStrings: (0, 5),
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.d,
    quality: '',
    rootString: 2,
    rootFret: 0,
    frets: [-1, -1, 0, 2, 3, 2],
    openFingers: [0, 0, 0, 1, 3, 2],
    movableFingers: [0, 0, 1, 3, 4, 2],
  ),
  _CagedShapeTemplate(
    shape: _CagedShape.d,
    quality: 'm',
    rootString: 2,
    rootFret: 0,
    frets: [-1, -1, 0, 2, 3, 1],
    openFingers: [0, 0, 0, 2, 3, 1],
    movableFingers: [0, 0, 1, 3, 4, 2],
  ),
];

const _guitarShapeTemplates = [
  _GuitarShapeTemplate(
    quality: '',
    rootString: 0,
    frets: [0, 2, 2, 1, 0, 0],
    openFingers: [0, 2, 3, 1, 0, 0],
    movableFingers: [1, 3, 4, 2, 1, 1],
    barreStrings: (0, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'm',
    rootString: 0,
    frets: [0, 2, 2, 0, 0, 0],
    openFingers: [0, 2, 3, 0, 0, 0],
    movableFingers: [1, 3, 4, 1, 1, 1],
    barreStrings: (0, 5),
  ),
  _GuitarShapeTemplate(
    quality: '7',
    rootString: 0,
    frets: [0, 2, 0, 1, 0, 0],
    openFingers: [0, 2, 0, 1, 0, 0],
    movableFingers: [1, 3, 1, 2, 1, 1],
    barreStrings: (0, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'maj7',
    rootString: 0,
    frets: [0, 2, 1, 1, 0, 0],
    openFingers: [0, 2, 1, 1, 0, 0],
    movableFingers: [1, 3, 2, 2, 1, 1],
    barreStrings: (0, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'm7',
    rootString: 0,
    frets: [0, 2, 0, 0, 0, 0],
    openFingers: [0, 2, 0, 0, 0, 0],
    movableFingers: [1, 3, 1, 1, 1, 1],
    barreStrings: (0, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'sus4',
    rootString: 0,
    frets: [0, 2, 2, 2, 0, 0],
    openFingers: [0, 2, 3, 4, 0, 0],
    movableFingers: [1, 3, 4, 4, 1, 1],
    barreStrings: (0, 5),
  ),
  _GuitarShapeTemplate(
    quality: '',
    rootString: 1,
    frets: [-1, 0, 2, 2, 2, 0],
    openFingers: [0, 0, 2, 3, 4, 0],
    movableFingers: [0, 1, 3, 3, 3, 1],
    barreStrings: (1, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'm',
    rootString: 1,
    frets: [-1, 0, 2, 2, 1, 0],
    openFingers: [0, 0, 2, 3, 1, 0],
    movableFingers: [0, 1, 3, 3, 2, 1],
    barreStrings: (1, 5),
  ),
  _GuitarShapeTemplate(
    quality: '7',
    rootString: 1,
    frets: [-1, 0, 2, 0, 2, 0],
    openFingers: [0, 0, 2, 0, 1, 0],
    movableFingers: [0, 1, 3, 1, 3, 1],
    barreStrings: (1, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'maj7',
    rootString: 1,
    frets: [-1, 0, 2, 1, 2, 0],
    openFingers: [0, 0, 2, 1, 3, 0],
    movableFingers: [0, 1, 3, 2, 4, 1],
    barreStrings: (1, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'm7',
    rootString: 1,
    frets: [-1, 0, 2, 0, 1, 0],
    openFingers: [0, 0, 2, 0, 1, 0],
    movableFingers: [0, 1, 3, 1, 2, 1],
    barreStrings: (1, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'sus4',
    rootString: 1,
    frets: [-1, 0, 2, 2, 3, 0],
    openFingers: [0, 0, 1, 2, 3, 0],
    movableFingers: [0, 1, 2, 2, 4, 1],
    barreStrings: (1, 5),
  ),
  _GuitarShapeTemplate(
    quality: '',
    rootString: 2,
    frets: [-1, -1, 0, 2, 3, 2],
    openFingers: [0, 0, 0, 1, 3, 2],
    movableFingers: [0, 0, 1, 3, 4, 2],
  ),
  _GuitarShapeTemplate(
    quality: 'm',
    rootString: 2,
    frets: [-1, -1, 0, 2, 3, 1],
    openFingers: [0, 0, 0, 2, 3, 1],
    movableFingers: [0, 0, 1, 3, 4, 2],
  ),
  _GuitarShapeTemplate(
    quality: '7',
    rootString: 2,
    frets: [-1, -1, 0, 2, 1, 2],
    openFingers: [0, 0, 0, 2, 1, 3],
    movableFingers: [0, 0, 1, 3, 2, 4],
  ),
  _GuitarShapeTemplate(
    quality: 'maj7',
    rootString: 2,
    frets: [-1, -1, 0, 2, 2, 2],
    openFingers: [0, 0, 0, 1, 2, 3],
    movableFingers: [0, 0, 1, 1, 1, 1],
    barreStrings: (2, 5),
  ),
  _GuitarShapeTemplate(
    quality: 'm7',
    rootString: 2,
    frets: [-1, -1, 0, 2, 1, 1],
    openFingers: [0, 0, 0, 2, 1, 1],
    movableFingers: [0, 0, 1, 3, 2, 2],
  ),
  _GuitarShapeTemplate(
    quality: 'sus4',
    rootString: 2,
    frets: [-1, -1, 0, 2, 3, 3],
    openFingers: [0, 0, 0, 1, 2, 3],
    movableFingers: [0, 0, 1, 2, 3, 3],
    barreStrings: (4, 5),
  ),
];

_GuitarChordShape? _guitarChordShape(
  String chord, {
  _CagedShape? selectedShape,
}) {
  final match = RegExp(
    r'^([A-Ga-g][#b]?)(maj7|m7|sus4|m|7)?(?:/([A-Ga-g][#b]?))?$',
    caseSensitive: false,
  ).firstMatch(chord);
  if (match == null) return null;

  int? pitch(String? note) {
    if (note == null) return null;
    return _chordPitchClasses['${note[0].toUpperCase()}${note.substring(1)}'];
  }

  final root = pitch(match.group(1));
  if (root == null) return null;
  final quality = match.group(2)?.toLowerCase() ?? '';
  final requestedBass = pitch(match.group(3));
  if (selectedShape != null) {
    if (requestedBass != null && requestedBass != root) return null;
    for (final template in _cagedShapeTemplates) {
      if (template.shape != selectedShape || template.quality != quality) {
        continue;
      }
      final rootFret =
          (root - _guitarStrings[template.rootString].pitch + 12) % 12;
      var shift = rootFret - template.rootFret;
      if (shift < 0) shift += 12;
      final frets = [
        for (final fret in template.frets)
          if (fret < 0) -1 else fret + shift,
      ];
      final pressedFrets = frets.where((fret) => fret > 0);
      final baseFret = shift == 0
          ? 0
          : pressedFrets.reduce(
              (first, second) => first < second ? first : second,
            );
      return _GuitarChordShape(
        frets: frets,
        fingers: shift == 0 ? template.openFingers : template.movableFingers,
        baseFret: baseFret,
        barreStrings: shift == 0 ? null : template.barreStrings,
      );
    }
    return null;
  }

  final candidates = <_GuitarChordShape>[];
  for (final template in _guitarShapeTemplates) {
    if (template.quality != quality) continue;
    final baseFret =
        (root - _guitarStrings[template.rootString].pitch + 12) % 12;
    final frets = [
      for (final fret in template.frets)
        if (fret < 0) -1 else if (baseFret == 0) fret else fret + baseFret,
    ];
    final lowestString = frets.indexWhere((fret) => fret >= 0);
    final bass =
        (_guitarStrings[lowestString].pitch + frets[lowestString]) % 12;
    if (requestedBass != null && requestedBass != bass) continue;
    candidates.add(
      _GuitarChordShape(
        frets: frets,
        fingers: baseFret == 0 ? template.openFingers : template.movableFingers,
        baseFret: baseFret,
        barreStrings: baseFret == 0 ? null : template.barreStrings,
      ),
    );
  }
  if (candidates.isEmpty) return null;
  candidates.sort((first, second) => first.baseFret.compareTo(second.baseFret));
  return candidates.first;
}

_CagedShape _defaultCagedShape(String chord) {
  final match = RegExp(
    r'^([A-Ga-g][#b]?)(maj7|m7|sus4|m|7)?(?:/([A-Ga-g][#b]?))?$',
    caseSensitive: false,
  ).firstMatch(chord);
  if (match == null) return _CagedShape.c;
  final root =
      _chordPitchClasses['${match.group(1)![0].toUpperCase()}${match.group(1)!.substring(1)}'];
  if (root == null) return _CagedShape.c;
  final quality = match.group(2)?.toLowerCase() ?? '';
  final candidates = _cagedShapeTemplates
      .where((template) => template.quality == quality)
      .map((template) {
        final rootFret =
            (root - _guitarStrings[template.rootString].pitch + 12) % 12;
        final shift = (rootFret - template.rootFret + 12) % 12;
        return (shape: template.shape, shift: shift);
      })
      .toList();
  if (candidates.isEmpty) return _CagedShape.c;
  candidates.sort((first, second) => first.shift.compareTo(second.shift));
  return candidates.first.shape;
}

({List<int> notes})? _chordNotes(String chord) {
  final match = RegExp(
    r'^([A-Ga-g][#b]?)(maj7|m7|sus4|dim|m|7)?(?:/([A-Ga-g][#b]?))?$',
    caseSensitive: false,
  ).firstMatch(chord);
  if (match == null) return null;

  int? pitch(String? note) {
    if (note == null) return null;
    final normalized = '${note[0].toUpperCase()}${note.substring(1)}';
    return _chordPitchClasses[normalized];
  }

  final root = pitch(match.group(1));
  if (root == null) return null;
  final quality = match.group(2)?.toLowerCase() ?? '';
  final intervals = switch (quality) {
    'm' => [0, 3, 7],
    '7' => [0, 4, 7, 10],
    'maj7' => [0, 4, 7, 11],
    'm7' => [0, 3, 7, 10],
    'sus4' => [0, 5, 7],
    'dim' => [0, 3, 6],
    _ => [0, 4, 7],
  };
  final notes = intervals.map((interval) => (root + interval) % 12).toList();
  final bass = pitch(match.group(3));
  if (bass != null && !notes.contains(bass)) notes.insert(0, bass);
  return (notes: notes);
}

class SongLibraryScreen extends StatefulWidget {
  const SongLibraryScreen({super.key, required this.viewModel});

  final SongLibraryViewModel viewModel;

  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen> {
  String _search = '';
  bool _isManagingBackup = false;

  Future<void> _createSong() async {
    final song = await showModalBottomSheet<NewSong>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SongFormSheet(),
    );
    if (song == null || !mounted) return;

    try {
      await widget.viewModel.addSong(song);
    } catch (error) {
      _showError('Não foi possível salvar a música: $error');
    }
  }

  Future<void> _setSongFavorite(Song song, bool isFavorite) async {
    try {
      await widget.viewModel.setSongFavorite(song.id!, isFavorite);
    } catch (error) {
      _showError('Não foi possível atualizar a favorita: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _handleBackupAction(_LibraryBackupAction action) {
    switch (action) {
      case _LibraryBackupAction.export:
        unawaited(_exportBackup());
      case _LibraryBackupAction.import:
        unawaited(_importBackup());
    }
  }

  Future<void> _exportBackup() async {
    if (_isManagingBackup) return;
    if (widget.viewModel.isLoading) {
      _showError('Aguarde o carregamento das cifras antes de exportar.');
      return;
    }
    if (widget.viewModel.loadError != null) {
      _showError('Não foi possível carregar as cifras para exportação.');
      return;
    }
    setState(() => _isManagingBackup = true);
    try {
      final saveLocation = await FilePicker.saveFile(
        dialogTitle: 'Salvar backup das cifras',
        fileName: 'cifras.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        mimeType: 'application/json',
        bytes: Uint8List.fromList(
          utf8.encode(encodeSongBackup(widget.viewModel.songs)),
        ),
      );
      if (saveLocation != null && mounted) {
        _showError('Backup salvo com sucesso.');
      }
    } catch (error) {
      if (mounted) _showError('Não foi possível exportar o backup: $error');
    } finally {
      if (mounted) setState(() => _isManagingBackup = false);
    }
  }

  Future<void> _importBackup() async {
    if (_isManagingBackup) return;
    setState(() => _isManagingBackup = true);
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Importar backup JSON',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (file == null || !mounted) return;

      final songs = decodeSongBackup(utf8.decode(await file.readAsBytes()));
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Substituir repertório?'),
          content: Text(
            'A importação substituirá todas as cifras atuais por '
            '${songs.length} ${songs.length == 1 ? 'cifra' : 'cifras'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Substituir'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      await widget.viewModel.replaceSongs(songs);
      if (mounted) {
        _showError(
          '${songs.length} ${songs.length == 1 ? 'cifra importada' : 'cifras importadas'}.',
        );
      }
    } catch (error) {
      if (mounted) _showError('Não foi possível importar o backup: $error');
    } finally {
      if (mounted) setState(() => _isManagingBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 22,
        title: Row(
          children: [
            const CifrasLogo(),
            const SizedBox(width: 10),
            const Text(
              'cifras',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<_LibraryBackupAction>(
            key: const ValueKey('backup-actions'),
            tooltip: 'Importar ou exportar JSON',
            enabled: !_isManagingBackup,
            onSelected: _handleBackupAction,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _LibraryBackupAction.export,
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Exportar JSON'),
                ),
              ),
              PopupMenuItem(
                value: _LibraryBackupAction.import,
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Importar JSON'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.viewModel,
        builder: (context, _) {
          final filteredSongs = widget.viewModel.songs
              .where((song) {
                final query = _search.trim().toLowerCase();
                return query.isEmpty ||
                    song.title.toLowerCase().contains(query) ||
                    song.artist.toLowerCase().contains(query);
              })
              .toList(growable: false);
          final favoriteSongs = filteredSongs
              .where((song) => song.isFavorite)
              .toList(growable: false);
          final otherSongs = filteredSongs
              .where((song) => !song.isFavorite)
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: widget.viewModel.load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
              children: [
                Text(
                  'Seu repertório',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Só acordes e estrutura. Sem letras.',
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 24),
                _RepertoireSummary(
                  songCount: widget.viewModel.songs.length,
                  onAdd: _createSong,
                ),
                const SizedBox(height: 24),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    hintText: 'Buscar música ou artista',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 18),
                if (widget.viewModel.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (widget.viewModel.loadError != null)
                  _LoadError(
                    error: widget.viewModel.loadError!,
                    onRetry: widget.viewModel.load,
                  )
                else if (filteredSongs.isEmpty &&
                    widget.viewModel.songs.isEmpty)
                  _EmptyLibrary(onAdd: _createSong)
                else if (filteredSongs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Nenhuma música encontrada.')),
                  )
                else ...[
                  _SongGroupHeading(
                    title: 'FAVORITAS',
                    count: favoriteSongs.length,
                  ),
                  const SizedBox(height: 10),
                  if (favoriteSongs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 18),
                      child: Text(
                        _search.trim().isEmpty
                            ? 'Toque no coração de uma cifra para adicioná-la aqui.'
                            : 'Nenhuma favorita encontrada.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                    )
                  else
                    ...favoriteSongs.map(
                      (song) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SongTile(
                          song: song,
                          onToggleFavorite: () => _setSongFavorite(song, false),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SongDetailScreen(
                                viewModel: widget.viewModel,
                                songId: song.id!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  _SongGroupHeading(
                    title: 'OUTRAS CIFRAS',
                    count: otherSongs.length,
                  ),
                  const SizedBox(height: 10),
                  if (otherSongs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 18),
                      child: Text(
                        'Todas as cifras estão nas favoritas.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                    )
                  else
                    ...otherSongs.map(
                      (song) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SongTile(
                          song: song,
                          onToggleFavorite: () => _setSongFavorite(song, true),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SongDetailScreen(
                                viewModel: widget.viewModel,
                                songId: song.id!,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isManagingBackup ? null : _createSong,
        icon: const Icon(Icons.add),
        label: const Text('Nova cifra'),
      ),
    );
  }
}

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({
    super.key,
    required this.viewModel,
    required this.songId,
  });

  final SongLibraryViewModel viewModel;
  final int songId;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  _ChordInstrument _instrument = _ChordInstrument.guitar;

  Future<void> _addSection() async {
    final section = await showModalBottomSheet<NewSection>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SectionFormSheet(
        initialTimeSignature: widget.viewModel.songs
            .firstWhere((song) => song.id == widget.songId)
            .timeSignature,
      ),
    );
    if (section == null || !mounted) return;

    try {
      await widget.viewModel.addSection(widget.songId, section);
    } catch (error) {
      _showError('Não foi possível salvar a seção: $error');
    }
  }

  Future<void> _deleteSong(Song song) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir cifra?'),
        content: Text(
          'A cifra de "${song.title}" e suas seções serão removidas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    try {
      await widget.viewModel.deleteSong(widget.songId);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _showError('Não foi possível excluir a cifra: $error');
    }
  }

  Future<void> _deleteSection(SongSection section) async {
    try {
      await widget.viewModel.deleteSection(section.id!);
    } catch (error) {
      _showError('Não foi possível excluir a seção: $error');
    }
  }

  Future<void> _changeSongKey(String key) async {
    try {
      await widget.viewModel.changeSongKey(widget.songId, key);
    } catch (error) {
      _showError('Não foi possível alterar o tom: $error');
    }
  }

  Future<void> _setSongFavorite(Song song, bool isFavorite) async {
    try {
      await widget.viewModel.setSongFavorite(song.id!, isFavorite);
    } catch (error) {
      _showError('Não foi possível atualizar a favorita: $error');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.viewModel,
      builder: (context, _) {
        final matches = widget.viewModel.songs.where(
          (song) => song.id == widget.songId,
        );
        if (matches.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final song = matches.first;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Cifra'),
            actions: [
              IconButton(
                tooltip: song.isFavorite
                    ? 'Remover das favoritas'
                    : 'Adicionar às favoritas',
                onPressed: () => _setSongFavorite(song, !song.isFavorite),
                icon: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: song.isFavorite ? AppColors.clay : null,
                ),
              ),
              IconButton(
                tooltip: 'Excluir cifra',
                onPressed: () => _deleteSong(song),
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 100),
            children: [
              Text(
                song.title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -1),
              ),
              if (song.artist.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  song.artist,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 20),
              _SongMetadata(song: song, onKeyChanged: _changeSongKey),
              const SizedBox(height: 22),
              Text(
                'Instrumento',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SegmentedButton<_ChordInstrument>(
                segments: const [
                  ButtonSegment(
                    value: _ChordInstrument.guitar,
                    label: Text('Violão'),
                    icon: Icon(Icons.music_note),
                  ),
                  ButtonSegment(
                    value: _ChordInstrument.keyboard,
                    label: Text('Teclado'),
                    icon: Icon(Icons.piano),
                  ),
                ],
                selected: {_instrument},
                onSelectionChanged: (selection) {
                  setState(() => _instrument = selection.first);
                },
              ),
              const SizedBox(height: 26),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Estrutura',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${song.sections.length} ${song.sections.length == 1 ? 'seção' : 'seções'}',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (song.sections.isEmpty)
                const _EmptySections()
              else
                ...song.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SectionCard(
                      section: section,
                      instrument: _instrument,
                      onDelete: () => _deleteSection(section),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addSection,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar seção'),
          ),
        );
      },
    );
  }
}

class _SongKeySelector extends StatelessWidget {
  const _SongKeySelector({required this.song, required this.onChanged});

  final Song song;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedKey = normalizeSongKey(song.key);
    final previousKey = selectedKey == null
        ? null
        : shiftSongKey(selectedKey, -1);
    final nextKey = selectedKey == null ? null : shiftSongKey(selectedKey, 1);
    return Row(
      children: [
        IconButton(
          key: const ValueKey('song-key-previous'),
          tooltip: 'Tom anterior: ${previousKey ?? 'indisponível'}',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 28),
          onPressed: previousKey == null ? null : () => onChanged(previousKey),
          icon: const Icon(Icons.chevron_left, size: 20),
        ),
        Expanded(
          child: Center(
            child: Text(
              selectedKey ?? '—',
              key: const ValueKey('song-key-current'),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('song-key-next'),
          tooltip: 'Próximo tom: ${nextKey ?? 'indisponível'}',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 28),
          onPressed: nextKey == null ? null : () => onChanged(nextKey),
          icon: const Icon(Icons.chevron_right, size: 20),
        ),
      ],
    );
  }
}

class _RepertoireSummary extends StatelessWidget {
  const _RepertoireSummary({required this.songCount, required this.onAdd});

  final int songCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.library_music_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$songCount ${songCount == 1 ? 'cifra salva' : 'cifras salvas'}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text('Organize por partes e compassos'),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Adicionar cifra',
            onPressed: onAdd,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  const _SongTile({
    required this.song,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Song song;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.paleGreen,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.music_note, color: AppColors.forest),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist.isEmpty
                          ? 'Artista não informado'
                          : song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _KeyBadge(song.key.isEmpty ? '—' : song.key),
                  const SizedBox(height: 5),
                  Text(
                    '${song.sections.length} ${song.sections.length == 1 ? 'parte' : 'partes'}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
              IconButton(
                tooltip: song.isFavorite
                    ? 'Remover das favoritas'
                    : 'Adicionar às favoritas',
                onPressed: onToggleFavorite,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  song.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: song.isFavorite ? AppColors.clay : AppColors.muted,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.chevron),
            ],
          ),
        ),
      ),
    );
  }
}

class _SongGroupHeading extends StatelessWidget {
  const _SongGroupHeading({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.muted,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.forest, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SongMetadata extends StatelessWidget {
  const _SongMetadata({required this.song, required this.onKeyChanged});

  final Song song;
  final ValueChanged<String> onKeyChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: width,
              child: _MetadataCard(
                label: 'TOM',
                content: _SongKeySelector(song: song, onChanged: onKeyChanged),
              ),
            ),
            SizedBox(
              width: width,
              child: _MetadataCard(
                label: 'ANDAMENTO',
                content: Text(
                  song.tempo == null ? '—' : '${song.tempo} BPM',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.label, required this.content});

  final String label;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 28,
            child: Align(alignment: Alignment.centerLeft, child: content),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.instrument,
    required this.onDelete,
  });

  final SongSection section;
  final _ChordInstrument instrument;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.segment,
                  size: 19,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Compasso: ${section.timeSignature}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                '${section.measures.length} c.',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              IconButton(
                tooltip: 'Excluir seção',
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 19),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              final gap = 8.0;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var index = 0; index < section.measures.length; index++)
                    SizedBox(
                      width: width,
                      child: _MeasureCard(
                        number: index + 1,
                        chords: section.measures[index],
                        instrument: instrument,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MeasureCard extends StatelessWidget {
  const _MeasureCard({
    required this.number,
    required this.chords,
    required this.instrument,
  });

  final int number;
  final String chords;
  final _ChordInstrument instrument;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMPASSO $number',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final chord in chords.split(RegExp(r'\s+')))
                _ChordButton(chord: chord, instrument: instrument),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChordButton extends StatelessWidget {
  const _ChordButton({required this.chord, required this.instrument});

  final String chord;
  final _ChordInstrument instrument;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ver acorde de $chord',
      child: Material(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) =>
                _ChordDiagramSheet(chord: chord, instrument: instrument),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            child: Text(
              chord,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.forest,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChordDiagramSheet extends StatelessWidget {
  const _ChordDiagramSheet({required this.chord, required this.instrument});

  final String chord;
  final _ChordInstrument instrument;

  @override
  Widget build(BuildContext context) {
    final chordNotes = _chordNotes(chord);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chord,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (instrument == _ChordInstrument.guitar)
              _GuitarChordDiagram(chord: chord)
            else if (chordNotes == null)
              const Text('Não foi possível exibir este acorde.')
            else ...[
              Text(
                'Notas: ${chordNotes.notes.map((note) => _chordPitchNames[note]).join(' · ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              _KeyboardChordDiagram(chordNotes: chordNotes),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuitarChordDiagram extends StatefulWidget {
  const _GuitarChordDiagram({required this.chord});

  final String chord;

  @override
  State<_GuitarChordDiagram> createState() => _GuitarChordDiagramState();
}

class _GuitarChordDiagramState extends State<_GuitarChordDiagram> {
  late _CagedShape _selectedShape;

  @override
  void initState() {
    super.initState();
    _selectedShape = _defaultCagedShape(widget.chord);
  }

  @override
  Widget build(BuildContext context) {
    final shape = _guitarChordShape(
      widget.chord,
      selectedShape: _selectedShape,
    );
    return Column(
      key: const ValueKey('guitar-chord-diagram'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Forma CAGED'),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cagedShape in _CagedShape.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: ValueKey('caged-shape-${cagedShape.name}'),
                    label: Text(cagedShape.name.toUpperCase()),
                    selected: _selectedShape == cagedShape,
                    onSelected: (_) {
                      setState(() => _selectedShape = cagedShape);
                    },
                  ),
                ),
            ],
          ),
        ),
        if (shape == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Esta forma CAGED está disponível para acordes maiores e menores '
              'com a fundamental no baixo.',
            ),
          )
        else ...[
          Text(
            shape.baseFret == 0
                ? 'Forma ${_selectedShape.name.toUpperCase()} · posição aberta'
                : 'Forma ${_selectedShape.name.toUpperCase()} · casa ${shape.baseFret}',
          ),
          const SizedBox(height: 10),
          SizedBox(
            key: const ValueKey('guitar-fretboard'),
            width: double.infinity,
            height: 196,
            child: CustomPaint(
              painter: _GuitarFretboardPainter(shape),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'X: não toque · O: corda solta · números: dedos',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _GuitarFretboardPainter extends CustomPainter {
  const _GuitarFretboardPainter(this.shape);

  final _GuitarChordShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 39.0;
    const right = 4.0;
    const top = 29.0;
    const bottom = 8.0;
    final neck = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final fretWidth = neck.width / 5;
    final stringGap = neck.height / (_guitarStrings.length - 1);

    canvas.drawRRect(
      RRect.fromRectAndRadius(neck, const Radius.circular(5)),
      Paint()..color = const Color(0xFFE8C99B),
    );

    final labelStyle = const TextStyle(
      color: AppColors.muted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );
    final firstFret = shape.baseFret <= 1 ? 1 : shape.baseFret;
    for (var fret = 0; fret <= 5; fret++) {
      final fretNumber = firstFret + fret;
      _drawLabel(
        canvas,
        '$fretNumber',
        Offset(left + fretWidth * (fret + 0.5), 11),
        labelStyle,
      );
    }

    final fretPaint = Paint()
      ..color = const Color(0xFF8A735B)
      ..strokeWidth = 2;
    for (var fret = 0; fret <= 5; fret++) {
      final x = left + fretWidth * fret;
      canvas.drawLine(Offset(x, top), Offset(x, neck.bottom), fretPaint);
    }
    if (shape.baseFret <= 1) {
      canvas.drawLine(
        Offset(left, top),
        Offset(left, neck.bottom),
        Paint()
          ..color = const Color(0xFFFAF7F0)
          ..strokeWidth = 5,
      );
    }

    final stringPaint = Paint()
      ..color = const Color(0xFF6C5842)
      ..strokeCap = StrokeCap.round;
    for (
      var stringIndex = 0;
      stringIndex < _guitarStrings.length;
      stringIndex++
    ) {
      final string = _guitarStrings[stringIndex];
      final y = top + stringGap * stringIndex;
      _drawLabel(
        canvas,
        string.name,
        Offset(12, y),
        const TextStyle(
          color: AppColors.forest,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );

      canvas.drawLine(
        Offset(left, y),
        Offset(neck.right, y),
        stringPaint..strokeWidth = 1.0 + stringIndex * 0.25,
      );

      final fret = shape.frets[stringIndex];
      if (fret < 0) {
        _drawLabel(
          canvas,
          '×',
          Offset(left - 14, y),
          const TextStyle(
            color: AppColors.clay,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        );
      } else if (fret == 0) {
        canvas.drawCircle(
          Offset(left - 14, y),
          5,
          Paint()
            ..color = AppColors.forest
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    final barre = shape.barreStrings;
    if (barre != null) {
      final barreFret = shape.baseFret;
      if (barreFret >= firstFret && barreFret < firstFret + 5) {
        final y1 = top + stringGap * barre.$1;
        final y2 = top + stringGap * barre.$2;
        final x = left + fretWidth * (barreFret - firstFret + 0.5);
        canvas.drawLine(
          Offset(x, y1),
          Offset(x, y2),
          Paint()
            ..color = AppColors.forest
            ..strokeWidth = 15
            ..strokeCap = StrokeCap.round,
        );
        _drawLabel(
          canvas,
          '${shape.fingers[barre.$1]}',
          Offset(x, (y1 + y2) / 2),
          const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        );
      }
    }

    final notePaint = Paint()..color = AppColors.forest;
    for (
      var stringIndex = 0;
      stringIndex < _guitarStrings.length;
      stringIndex++
    ) {
      final fret = shape.frets[stringIndex];
      if (fret <= 0) continue;
      final finger = shape.fingers[stringIndex];
      if (finger == 0) continue;
      final barre = shape.barreStrings;
      if (barre != null &&
          stringIndex >= barre.$1 &&
          stringIndex <= barre.$2 &&
          fret == shape.frets[barre.$1] &&
          finger == shape.fingers[barre.$1]) {
        continue;
      }
      final fretInView = fret - firstFret;
      if (fretInView < 0 || fretInView >= 5) continue;
      final x = left + fretWidth * (fretInView + 0.5);
      final y = top + stringGap * stringIndex;
      canvas.drawCircle(Offset(x, y), 11, notePaint);
      _drawLabel(
        canvas,
        '$finger',
        Offset(x, y),
        const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
    }
  }

  void _drawLabel(Canvas canvas, String label, Offset center, TextStyle style) {
    final text = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
  }

  @override
  bool shouldRepaint(covariant _GuitarFretboardPainter oldDelegate) =>
      oldDelegate.shape != shape;
}

class _KeyboardChordDiagram extends StatelessWidget {
  const _KeyboardChordDiagram({required this.chordNotes});

  final ({List<int> notes}) chordNotes;

  @override
  Widget build(BuildContext context) {
    final highlighted = chordNotes.notes.toSet();
    return Column(
      key: const ValueKey('keyboard-chord-diagram'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notas destacadas em duas oitavas'),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: _KeyboardPainter(highlighted),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _KeyboardPainter extends CustomPainter {
  const _KeyboardPainter(this.highlighted);

  final Set<int> highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    const whiteNotes = [0, 2, 4, 5, 7, 9, 11];
    const blackNotes = [1, 3, 6, 8, 10];
    const blackOffsets = [1, 2, 4, 5, 6];
    final whiteWidth = size.width / 14;
    final whitePaint = Paint()..color = Colors.white;
    final highlightedPaint = Paint()..color = AppColors.softGreen;
    final borderPaint = Paint()
      ..color = AppColors.muted
      ..style = PaintingStyle.stroke;

    for (var key = 0; key < 14; key++) {
      final pitch = whiteNotes[key % 7];
      final rect = Rect.fromLTWH(key * whiteWidth, 0, whiteWidth, size.height);
      canvas.drawRect(
        rect,
        highlighted.contains(pitch) ? highlightedPaint : whitePaint,
      );
      canvas.drawRect(rect, borderPaint);
    }

    final blackWidth = whiteWidth * 0.62;
    final blackHeight = size.height * 0.62;
    final blackPaint = Paint()..color = const Color(0xFF333333);
    final highlightedBlackPaint = Paint()..color = AppColors.forest;
    for (var octave = 0; octave < 2; octave++) {
      for (var index = 0; index < blackNotes.length; index++) {
        final pitch = blackNotes[index];
        final rect = Rect.fromLTWH(
          (octave * 7 + blackOffsets[index]) * whiteWidth - blackWidth / 2,
          0,
          blackWidth,
          blackHeight,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          highlighted.contains(pitch) ? highlightedBlackPaint : blackPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _KeyboardPainter oldDelegate) =>
      oldDelegate.highlighted != highlighted;
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.library_music_outlined,
              size: 30,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sua primeira cifra começa aqui',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          const Text(
            'Cadastre uma música e organize os acordes por partes.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Criar primeira cifra'),
          ),
        ],
      ),
    );
  }
}

class _EmptySections extends StatelessWidget {
  const _EmptySections();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: AppColors.forest),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Adicione uma parte e distribua os acordes em compassos.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 32),
          const SizedBox(height: 8),
          const Text('Não foi possível carregar suas cifras.'),
          const SizedBox(height: 4),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _SongFormSheet extends StatefulWidget {
  const _SongFormSheet();

  @override
  State<_SongFormSheet> createState() => _SongFormSheetState();
}

class _SongFormSheetState extends State<_SongFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _key = TextEditingController();
  final _tempo = TextEditingController();
  String _timeSignature = '4/4';

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _key.dispose();
    _tempo.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final tempoText = _tempo.text.trim();
    Navigator.pop(
      context,
      NewSong(
        title: _title.text.trim(),
        artist: _artist.text.trim(),
        key: _key.text.trim(),
        tempo: tempoText.isEmpty ? null : int.parse(tempoText),
        timeSignature: _timeSignature,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetFrame(
      title: 'Nova cifra',
      subtitle: 'Identifique a música. A letra não é necessária.',
      onSave: _save,
      saveLabel: 'Criar cifra',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome da música',
                hintText: 'Ex.: Caminho de casa',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o nome da música.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _artist,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Artista (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _key,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Tom (opcional)',
                      hintText: 'Am',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _tempo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'BPM (opcional)',
                      hintText: '92',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      final tempo = int.tryParse(value.trim());
                      if (tempo == null || tempo < 1 || tempo > 400) {
                        return 'Use um valor entre 1 e 400.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _timeSignature,
              decoration: const InputDecoration(
                labelText: 'Fórmula de compasso',
                helperText: 'Quantidade e tipo de tempos em cada compasso.',
              ),
              items: _timeSignatures
                  .map(
                    (signature) => DropdownMenuItem(
                      value: signature,
                      child: Text(signature),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _timeSignature = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionFormSheet extends StatefulWidget {
  const _SectionFormSheet({required this.initialTimeSignature});

  final String initialTimeSignature;

  @override
  State<_SectionFormSheet> createState() => _SectionFormSheetState();
}

class _SectionFormSheetState extends State<_SectionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final List<List<String>> _measures = [[]];
  String _sectionName = _sectionNames.first;
  late String _timeSignature = widget.initialTimeSignature;
  String _chordRoot = _chordRoots.first;
  String _chordQuality = _chordQualities.keys.first;
  String? _validationError;

  bool get _hasChords => _measures.any((measure) => measure.isNotEmpty);

  void _addChord() {
    setState(() {
      _measures.last.add('$_chordRoot${_chordQualities[_chordQuality]}');
      _validationError = null;
    });
  }

  void _addMeasure() {
    setState(() => _measures.add([]));
  }

  void _removeMeasure(int index) {
    setState(() => _measures.removeAt(index));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChords) {
      setState(() => _validationError = 'Adicione ao menos um acorde.');
      return;
    }
    Navigator.pop(
      context,
      NewSection(
        title: _sectionName,
        timeSignature: _timeSignature,
        measures: _measures
            .where((measure) => measure.isNotEmpty)
            .map((measure) => measure.join(' '))
            .toList(growable: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FormSheetFrame(
      title: 'Adicionar seção',
      subtitle: 'Selecione os acordes e organize-os em compassos.',
      onSave: _save,
      saveLabel: 'Salvar seção',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _sectionName,
              decoration: const InputDecoration(labelText: 'Parte da música'),
              items: _sectionNames
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _sectionName = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _timeSignature,
              decoration: const InputDecoration(
                labelText: 'Fórmula de compasso',
              ),
              items: _timeSignatures
                  .map(
                    (signature) => DropdownMenuItem(
                      value: signature,
                      child: Text(signature),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _timeSignature = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _chordRoot,
                    decoration: const InputDecoration(labelText: 'Nota'),
                    items: _chordRoots
                        .map(
                          (root) =>
                              DropdownMenuItem(value: root, child: Text(root)),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) setState(() => _chordRoot = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _chordQuality,
                    decoration: const InputDecoration(labelText: 'Acorde'),
                    items: _chordQualities.keys
                        .map(
                          (quality) => DropdownMenuItem(
                            value: quality,
                            child: Text(quality),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _chordQuality = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addChord,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar acorde ao compasso'),
              ),
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < _measures.length; index++) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.parchment,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'COMPASSO ${index + 1}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_measures.length > 1)
                          IconButton(
                            tooltip: 'Remover compasso',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _removeMeasure(index),
                            icon: const Icon(Icons.delete_outline, size: 19),
                          ),
                      ],
                    ),
                    if (_measures[index].isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Nenhum acorde selecionado'),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final chord in _measures[index])
                            InputChip(
                              label: Text(chord),
                              onDeleted: () {
                                setState(() => _measures[index].remove(chord));
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            TextButton.icon(
              onPressed: _addMeasure,
              icon: const Icon(Icons.add),
              label: const Text('Novo compasso'),
            ),
            if (_validationError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _validationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormSheetFrame extends StatelessWidget {
  const _FormSheetFrame({
    required this.title,
    required this.subtitle,
    required this.onSave,
    required this.saveLabel,
    required this.child,
  });

  final String title;
  final String subtitle;
  final VoidCallback onSave;
  final String saveLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          14,
          22,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSave,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(saveLabel),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
