import 'package:cifras/domain/music_transposition.dart';
import 'package:cifras/domain/database_sync_service.dart';
import 'package:cifras/domain/song.dart';
import 'package:cifras/domain/song_repository.dart';
import 'package:cifras/main.dart';
import 'package:cifras/presentation/cifras_logo.dart';
import 'package:cifras/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detecta alterações locais, remotas e conflitos de sincronização', () {
    expect(
      determineDatabaseSyncAction(
        localHash: 'local',
        driveHash: null,
        lastSyncHash: null,
      ),
      DatabaseSyncAction.uploadLocal,
    );
    expect(
      determineDatabaseSyncAction(
        localHash: 'common',
        driveHash: 'remote',
        lastSyncHash: 'common',
      ),
      DatabaseSyncAction.downloadDrive,
    );
    expect(
      determineDatabaseSyncAction(
        localHash: 'local',
        driveHash: 'common',
        lastSyncHash: 'common',
      ),
      DatabaseSyncAction.uploadLocal,
    );
    expect(
      determineDatabaseSyncAction(
        localHash: 'local',
        driveHash: 'remote',
        lastSyncHash: 'common',
      ),
      DatabaseSyncAction.conflict,
    );
    expect(
      determineDatabaseSyncAction(
        localHash: 'same',
        driveHash: 'same',
        lastSyncHash: null,
      ),
      DatabaseSyncAction.alreadySynced,
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

  testWidgets('cadastra uma música e organiza acordes por seção', (
    tester,
  ) async {
    final repository = _MemorySongRepository();
    await tester.pumpWidget(CifrasApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Seu repertório'), findsOneWidget);
    expect(find.text('Sua primeira cifra começa aqui'), findsOneWidget);

    await tester.tap(find.text('Nova cifra'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Canção teste');
    await tester.enterText(find.byType(TextFormField).at(2), 'Am');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3/4').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar cifra'));
    await tester.pumpAndSettle();

    expect(find.text('Canção teste'), findsOneWidget);
    await tester.tap(find.text('Canção teste'));
    await tester.pumpAndSettle();
    expect(find.text('COMPASSO'), findsNothing);
    await tester.tap(find.text('Adicionar seção'));
    await tester.pumpAndSettle();
    expect(find.text('3/4'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5/4').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar acorde ao compasso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo compasso'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maior').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar acorde ao compasso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Novo compasso'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar acorde ao compasso'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Remover compasso').last);
    await tester.pumpAndSettle();
    expect(find.text('COMPASSO 3'), findsNothing);
    await tester.tap(find.text('Salvar seção'));
    await tester.pumpAndSettle();

    expect(find.text('Intro'), findsOneWidget);
    expect(find.text('Compasso: 5/4'), findsOneWidget);
    expect(find.text('COMPASSO 1'), findsOneWidget);
    expect(find.text('Am'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('D'), findsNothing);
    expect(find.text('COMPASSO 2'), findsOneWidget);
    expect(find.textContaining('letra'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('song-key-next')));
    await tester.pumpAndSettle();

    expect(find.text('A#m'), findsNWidgets(2));
    expect(find.text('C#'), findsOneWidget);
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

  testWidgets('exibe a escolha de versão ao sincronizar', (tester) async {
    final syncService = _FakeDatabaseSyncService();
    await tester.pumpWidget(
      CifrasApp(
        repository: _MemorySongRepository(),
        databaseSyncService: syncService,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sincronizar com Google Drive'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Escolha o banco para sincronizar'), findsOneWidget);
    await tester.tap(find.text('Enviar versão local'));
    await tester.pumpAndSettle();

    expect(syncService.choice, DatabaseSyncChoice.uploadLocal);
    expect(find.text('Banco enviado ao Google Drive.'), findsOneWidget);
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

class _FakeDatabaseSyncService implements DatabaseSyncService {
  DatabaseSyncChoice? choice;

  @override
  Future<DatabaseSyncResult> synchronize({
    required Future<DatabaseSyncChoice?> Function({required bool isFirstSync})
    resolveConflict,
  }) async {
    choice = await resolveConflict(isFirstSync: true);
    return choice == DatabaseSyncChoice.uploadLocal
        ? DatabaseSyncResult.uploaded
        : DatabaseSyncResult.cancelled;
  }
}

class _MemorySongRepository implements SongRepository {
  final List<Song> _songs = [];
  var _nextSongId = 1;
  var _nextSectionId = 1;

  @override
  Future<List<Song>> getSongs() async => List.unmodifiable(_songs);

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
}
