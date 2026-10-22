import 'package:cifras/domain/music_transposition.dart';
import 'package:cifras/domain/song.dart';
import 'package:cifras/domain/song_backup.dart';
import 'package:cifras/domain/song_repository.dart';
import 'package:cifras/main.dart';
import 'package:cifras/presentation/cifras_logo.dart';
import 'package:cifras/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup JSON preserva os dados das cifras e das seções', () {
    final songs = [
      const Song(
        id: 12,
        title: 'Canção teste',
        artist: 'Artista',
        key: 'Am',
        tempo: 96,
        timeSignature: '3/4',
        isFavorite: true,
        sections: [
          SongSection(
            id: 7,
            songId: 12,
            title: 'Refrão',
            measures: ['Am G', 'C'],
            position: 2,
            timeSignature: '5/4',
          ),
        ],
      ),
    ];

    final decoded = decodeSongBackup(encodeSongBackup(songs));

    expect(decoded, hasLength(1));
    expect(decoded.single.title, 'Canção teste');
    expect(decoded.single.artist, 'Artista');
    expect(decoded.single.key, 'Am');
    expect(decoded.single.tempo, 96);
    expect(decoded.single.timeSignature, '3/4');
    expect(decoded.single.isFavorite, isTrue);
    expect(decoded.single.sections, hasLength(1));
    expect(decoded.single.sections.single.title, 'Refrão');
    expect(decoded.single.sections.single.measures, ['Am G', 'C']);
    expect(decoded.single.sections.single.position, 2);
    expect(decoded.single.sections.single.timeSignature, '5/4');
  });

  test('rejeita backups JSON inválidos ou de versão não suportada', () {
    expect(() => decodeSongBackup('{'), throwsFormatException);
    expect(
      () => decodeSongBackup('{"format":"cifras","version":99,"songs":[]}'),
      throwsFormatException,
    );
    expect(
      () => decodeSongBackup(
        '{"format":"cifras","version":1,"songs":[{"title":3}]}',
      ),
      throwsFormatException,
    );
  });

  test('compassos são separados e espaços excedentes são normalizados', () {
    expect(SongSection.parseMeasures(' Am   G/B | C | | F  Dm '), [
      'Am G/B',
      'C',
      'F Dm',
    ]);
    expect(SongSection.parseMeasures(' |  | '), isEmpty);
  });

  test('transpõe acordes e baixos mantendo a qualidade', () {
    expect(transposeChord('Am', 2), 'Bm');
    expect(transposeChord('G7/B', 5), 'C7/E');
    expect(transposeChord('Fmaj7', 2), 'Gmaj7');
    expect(normalizeSongKey('A minor'), 'Am');
    expect(songKeyInterval('Am', 'Dm'), 5);
    expect(shiftSongKey('D', -1), 'C#');
    expect(shiftSongKey('D', 1), 'D#');
    expect(shiftSongKey('Am', 1), 'A#m');
  });

  testWidgets('compasso só pode ser definido ao adicionar uma seção', (
    tester,
  ) async {
    final repository = _MemorySongRepository();
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova cifra'));
    await tester.pumpAndSettle();
    expect(find.text('Fórmula de compasso'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Canção teste');
    await tester.tap(find.text('Criar cifra'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Canção teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar seção'));
    await tester.pumpAndSettle();
    expect(find.text('Fórmula de compasso'), findsOneWidget);
    expect(find.text('4/4'), findsOneWidget);
  });

  testWidgets('cadastra uma música e organiza acordes por seção', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _MemorySongRepository();
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Seu repertório'), findsOneWidget);
    expect(find.text('Sua primeira cifra começa aqui'), findsOneWidget);

    await tester.tap(find.text('Nova cifra'));
    await tester.pumpAndSettle();
    expect(find.text('Fórmula de compasso'), findsNothing);
    await tester.enterText(find.byType(TextFormField).first, 'Canção teste');
    await tester.enterText(find.byType(TextFormField).at(2), 'Am');
    await tester.tap(find.text('Criar cifra'));
    await tester.pumpAndSettle();

    expect(find.text('Canção teste'), findsOneWidget);
    await tester.tap(find.text('Canção teste'));
    await tester.pumpAndSettle();
    expect(find.text('COMPASSO'), findsNothing);
    await tester.tap(find.text('Adicionar seção'));
    await tester.pumpAndSettle();
    expect(find.text('4/4'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5/4').last);
    await tester.pumpAndSettle();
    expect(find.text('Nota'), findsNothing);
    expect(find.text('Acorde'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('section-chord-dictionary-search')),
      'Am',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-dictionary-chord-Am')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Novo compasso'));
    await tester.tap(find.text('Novo compasso'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('section-chord-dictionary-search')),
      'C',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-dictionary-chord-C')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Novo compasso'));
    await tester.tap(find.text('Novo compasso'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('section-chord-dictionary-search')),
      'D',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-dictionary-chord-D')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover compasso').last);
    await tester.pumpAndSettle();
    expect(find.text('COMPASSO 3'), findsNothing);
    await tester.ensureVisible(find.text('Salvar seção'));
    await tester.tap(find.text('Salvar seção'));
    await tester.pumpAndSettle();

    expect(find.text('Intro'), findsOneWidget);
    expect(find.text('Compasso: 5/4'), findsOneWidget);
    expect(find.text('COMPASSO 1'), findsOneWidget);
    expect(find.text('Am'), findsNWidgets(2));
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('COMPASSO 2'), findsOneWidget);
    expect(find.textContaining('letra'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('song-key-next')));
    await tester.pumpAndSettle();

    expect(find.text('A#m'), findsOneWidget);
    expect(find.text('Bbm'), findsOneWidget);
    expect(find.text('C#'), findsOneWidget);
  });

  testWidgets('busca acordes no dicionário e exibe diagramas por instrumento', (
    tester,
  ) async {
    await tester.pumpWidget(CifrasApp(repository: _MemorySongRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dicionário de acordes'));
    await tester.pumpAndSettle();
    expect(find.text('Dicionário de acordes'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('chord-dictionary-search')),
      'Am',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dictionary-chord-Am')), findsOneWidget);
    await tester.tap(find.text('Teclado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dictionary-chord-Am')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('keyboard-chord-diagram')),
      findsOneWidget,
    );
    expect(find.text('Notas: A · C · E'), findsNothing);
  });

  testWidgets('exibe acordes diminutos no teclado e no violão', (tester) async {
    await tester.pumpWidget(CifrasApp(repository: _MemorySongRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Dicionário de acordes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chord-dictionary-search')),
      'Cdim',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dictionary-chord-Cdim')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dictionary-chord-Cdim')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-chord-diagram')), findsOneWidget);
    expect(find.byKey(const ValueKey('guitar-fretboard-0')), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teclado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dictionary-chord-Cdim')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('keyboard-chord-diagram')),
      findsOneWidget,
    );
    expect(find.text('Notas: C · Eb · F#'), findsNothing);
  });

  testWidgets('adiciona um acorde encontrado no dicionário à seção', (
    tester,
  ) async {
    final repository = _MemorySongRepository();
    await repository.addSong(
      const NewSong(title: 'Canção teste', artist: '', key: 'Am', tempo: null),
    );
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canção teste'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar seção'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('section-chord-dictionary-search')),
      'F#',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('section-dictionary-chord-F#')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: find.byType(InputChip), matching: find.text('F#')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Salvar seção'));
    await tester.tap(find.text('Salvar seção'));
    await tester.pumpAndSettle();

    final songs = await repository.getSongs();
    expect(songs.single.sections.single.measures, ['F#']);
  });

  testWidgets('mantém os cards de tom e andamento com a mesma altura', (
    tester,
  ) async {
    final repository = _MemorySongRepository();
    await repository.addSong(
      const NewSong(
        title: 'Canção teste',
        artist: '',
        key: 'Am',
        tempo: null,
        timeSignature: '4/4',
      ),
    );
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canção teste'));
    await tester.pumpAndSettle();

    final keyCard = find
        .ancestor(of: find.text('TOM'), matching: find.byType(Container))
        .first;
    final tempoCard = find
        .ancestor(of: find.text('ANDAMENTO'), matching: find.byType(Container))
        .first;
    expect(tester.getSize(keyCard).height, tester.getSize(tempoCard).height);
  });

  testWidgets('exibe acordes no instrumento selecionado', (tester) async {
    final repository = _MemorySongRepository();
    await repository.addSong(
      const NewSong(title: 'Canção teste', artist: '', key: 'Am', tempo: null),
    );
    await repository.addSection(
      1,
      const NewSection(title: 'Verso', measures: ['Am G C F#']),
    );
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canção teste'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver acorde de Am'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-chord-diagram')), findsOneWidget);
    expect(find.byKey(const ValueKey('guitar-shape-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('guitar-shape-1')), findsNothing);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver acorde de G'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-fretboard-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('guitar-shape-1')), findsNothing);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver acorde de C'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-fretboard-0')), findsOneWidget);
    final fretboard = find.byKey(const ValueKey('guitar-fretboard-0'));
    final fretRange = find.byKey(const ValueKey('guitar-fret-range-0'));
    final previousFret = find.byKey(const ValueKey('guitar-fret-previous-0'));
    final nextFret = find.byKey(const ValueKey('guitar-fret-next-0'));
    expect(fretRange, findsOneWidget);
    expect(find.text('Casas 1–5'), findsOneWidget);
    await tester.tap(nextFret);
    await tester.pumpAndSettle();
    expect(find.text('Casas 2–6'), findsOneWidget);
    await tester.tap(previousFret);
    await tester.pumpAndSettle();
    expect(find.text('Casas 1–5'), findsOneWidget);
    await tester.tap(nextFret);
    await tester.pumpAndSettle();

    final fretboardTopLeft = tester.getTopLeft(fretboard);
    final fretboardSize = tester.getSize(fretboard);
    await tester.tapAt(
      fretboardTopLeft + Offset(39 + (fretboardSize.width - 43) / 10, 30),
    );
    await tester.pumpAndSettle();
    expect(find.text('Casas 2–6'), findsOneWidget);
    expect(find.text('Toque em uma casa para selecionar a nota'), findsNothing);

    for (var fret = 2; fret < 20; fret++) {
      await tester.tap(nextFret);
      await tester.pumpAndSettle();
    }
    expect(find.text('Casas 20–24'), findsOneWidget);
    await tester.tap(nextFret);
    await tester.pumpAndSettle();
    expect(find.text('Casas 20–24'), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ver acorde de F#'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-shape-0')), findsOneWidget);
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Teclado'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ver acorde de Am'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('keyboard-chord-diagram')),
      findsOneWidget,
    );
    expect(find.text('Notas destacadas em duas oitavas'), findsNothing);
  });

  testWidgets('salva e reabre shapes editados pelo toque', (tester) async {
    final repository = _MemorySongRepository();
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Dicionário de acordes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('chord-dictionary-search')),
      'Am',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dictionary-chord-Am')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('add-guitar-shape')));
    await tester.tap(find.byKey(const ValueKey('add-guitar-shape')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-shape-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('guitar-shape-1')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('guitar-fretboard-0')),
    );
    final fretboard = find.byKey(const ValueKey('guitar-fretboard-0'));
    final fretboardTopLeft = tester.getTopLeft(fretboard);
    final fretboardSize = tester.getSize(fretboard);
    await tester.tapAt(
      fretboardTopLeft + Offset(39 + (fretboardSize.width - 43) / 10, 30),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-guitar-shapes')),
    );
    await tester.tap(find.byKey(const ValueKey('save-guitar-shapes')));
    await tester.pumpAndSettle();
    final savedShapes = await repository.getChordShapes('Am');
    expect(savedShapes, hasLength(2));
    expect(savedShapes.first.frets.first, isNot(-1));
    await tester.ensureVisible(find.byTooltip('Fechar'));
    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dictionary-chord-Am')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('guitar-shape-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('guitar-shape-1')), findsOneWidget);
  });

  testWidgets('aplica a identidade visual e exibe a marca', (tester) async {
    await tester.pumpWidget(CifrasApp(repository: _MemorySongRepository()));
    await tester.pumpAndSettle();

    expect(find.byType(CifrasLogo), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('cifras'))).colorScheme.primary,
      AppColors.forest,
    );
    expect(
      Theme.of(tester.element(find.text('Seu repertório')))
          .scaffoldBackgroundColor,
      AppColors.parchment,
    );
  });

  testWidgets('exibe as ações de exportação e importação JSON', (tester) async {
    await tester.pumpWidget(CifrasApp(repository: _MemorySongRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Importar ou exportar JSON'));
    await tester.pumpAndSettle();

    expect(find.text('Exportar JSON'), findsOneWidget);
    expect(find.text('Importar JSON'), findsOneWidget);
    expect(find.textContaining('Google Drive'), findsNothing);
  });

  testWidgets('favorita e desfavorita cifras na biblioteca', (tester) async {
    final repository = _MemorySongRepository();
    await repository.addSong(
      const NewSong(
        title: 'Canção favorita',
        artist: 'Artista',
        key: 'C',
        tempo: null,
      ),
    );
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('FAVORITAS'), findsOneWidget);
    expect(find.text('Canção favorita'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar às favoritas'));
    await tester.pumpAndSettle();

    expect(find.text('Canção favorita'), findsOneWidget);
    expect(find.text('OUTRAS CIFRAS'), findsOneWidget);
    expect(find.text('Todas as cifras estão nas favoritas.'), findsOneWidget);
    expect(find.byTooltip('Remover das favoritas'), findsOneWidget);

    await tester.tap(find.byTooltip('Remover das favoritas'));
    await tester.pumpAndSettle();

    expect(find.text('Canção favorita'), findsOneWidget);
    expect(
      find.text('Toque no coração de uma cifra para adicioná-la aqui.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Adicionar às favoritas'), findsOneWidget);
  });
}

class _MemorySongRepository implements SongRepository {
  final List<Song> _songs = [];
  final Map<String, List<GuitarChordShape>> _chordShapes = {};
  var _nextSongId = 1;
  var _nextSectionId = 1;

  @override
  Future<List<Song>> getSongs() async => List.unmodifiable(_songs);

  @override
  Future<void> replaceSongs(List<Song> songs) async {
    _songs
      ..clear()
      ..addAll([
        for (final song in songs)
          Song(
            id: _nextSongId++,
            title: song.title,
            artist: song.artist,
            key: song.key,
            tempo: song.tempo,
            timeSignature: song.timeSignature,
            isFavorite: song.isFavorite,
            sections: [
              for (final section in song.sections)
                SongSection(
                  id: _nextSectionId++,
                  songId: _nextSongId - 1,
                  title: section.title,
                  measures: section.measures,
                  position: section.position,
                  timeSignature: section.timeSignature,
                ),
            ],
          ),
      ]);
  }

  @override
  Future<void> addSong(NewSong song) async {
    _songs.insert(
      0,
      Song(
        id: _nextSongId++,
        title: song.title,
        artist: song.artist,
        key: song.key,
        tempo: song.tempo,
        timeSignature: song.timeSignature,
      ),
    );
  }

  @override
  Future<void> changeSongKey(int songId, String key) async {
    final index = _songs.indexWhere((song) => song.id == songId);
    final song = _songs[index];
    final interval = songKeyInterval(song.key, key);
    _songs[index] = Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      key: key,
      tempo: song.tempo,
      timeSignature: song.timeSignature,
      isFavorite: song.isFavorite,
      sections: [
        for (final section in song.sections)
          SongSection(
            id: section.id,
            songId: section.songId,
            title: section.title,
            measures: interval == null || interval == 0
                ? section.measures
                : transposeMeasures(section.measures, interval),
            position: section.position,
            timeSignature: section.timeSignature,
          ),
      ],
    );
  }

  @override
  Future<void> setSongFavorite(int songId, bool isFavorite) async {
    final index = _songs.indexWhere((song) => song.id == songId);
    final song = _songs[index];
    _songs[index] = Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      key: song.key,
      tempo: song.tempo,
      timeSignature: song.timeSignature,
      isFavorite: isFavorite,
      sections: song.sections,
    );
  }

  @override
  Future<void> deleteSong(int songId) async {
    _songs.removeWhere((song) => song.id == songId);
  }

  @override
  Future<void> addSection(int songId, NewSection section) async {
    final index = _songs.indexWhere((song) => song.id == songId);
    final song = _songs[index];
    final sections = [...song.sections];
    sections.add(
      SongSection(
        id: _nextSectionId++,
        songId: songId,
        title: section.title,
        measures: section.measures,
        position: sections.length,
        timeSignature: section.timeSignature,
      ),
    );
    _songs[index] = Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      key: song.key,
      tempo: song.tempo,
      timeSignature: song.timeSignature,
      isFavorite: song.isFavorite,
      sections: sections,
    );
  }

  @override
  Future<void> deleteSection(int sectionId) async {
    for (var index = 0; index < _songs.length; index++) {
      final song = _songs[index];
      final sections = song.sections
          .where((section) => section.id != sectionId)
          .toList();
      _songs[index] = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        key: song.key,
        tempo: song.tempo,
        timeSignature: song.timeSignature,
        isFavorite: song.isFavorite,
        sections: sections,
      );
    }
  }

  @override
  Future<List<GuitarChordShape>> getChordShapes(String chord) async =>
      List.unmodifiable(_chordShapes[chord] ?? const []);

  @override
  Future<void> saveChordShapes(
    String chord,
    List<GuitarChordShape> shapes,
  ) async {
    _chordShapes[chord] = List.of(shapes);
  }
}
