import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/music_transposition.dart';
import '../domain/song.dart';
import '../domain/song_repository.dart';

class SqliteSongRepository implements SongRepository {
  Database? _database;

  Future<Database> get _db async {
    final database = _database;
    if (database != null) return database;

    final databasePath = path.join(await getDatabasesPath(), 'cifras.db');
    final openedDatabase = await openDatabase(
      databasePath,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE songs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            artist TEXT NOT NULL,
            song_key TEXT NOT NULL,
            tempo INTEGER,
            time_signature TEXT NOT NULL DEFAULT '4/4'
          )
        ''');
        await db.execute('''
          CREATE TABLE sections (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            song_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            measures TEXT NOT NULL,
            position INTEGER NOT NULL,
            FOREIGN KEY (song_id) REFERENCES songs (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE songs ADD COLUMN time_signature TEXT NOT NULL DEFAULT '4/4'",
          );
        }
      },
    );
    _database = openedDatabase;
    return openedDatabase;
  }

  @override
  Future<List<Song>> getSongs() async {
    final db = await _db;
    final songRows = await db.query('songs', orderBy: 'id DESC');
    final sectionRows = await db.query('sections', orderBy: 'position ASC');

    return songRows
        .map((row) {
          final songId = row['id']! as int;
          final sections = sectionRows
              .where((section) => section['song_id'] == songId)
              .map(
                (section) => SongSection(
                  id: section['id']! as int,
                  songId: songId,
                  title: section['title']! as String,
                  measures: (jsonDecode(section['measures']! as String) as List)
                      .cast<String>(),
                  position: section['position']! as int,
                ),
              )
              .toList(growable: false);

          return Song(
            id: songId,
            title: row['title']! as String,
            artist: row['artist']! as String,
            key: row['song_key']! as String,
            tempo: row['tempo'] as int?,
            timeSignature: row['time_signature']! as String,
            sections: sections,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<void> addSong(NewSong song) async {
    final db = await _db;
    await db.insert('songs', {
      'title': song.title,
      'artist': song.artist,
      'song_key': song.key,
      'tempo': song.tempo,
      'time_signature': song.timeSignature,
    });
  }

  @override
  Future<void> changeSongKey(int songId, String key) async {
    final targetKey = normalizeSongKey(key);
    if (targetKey == null) {
      throw FormatException('O tom "$key" não é válido.');
    }

    final db = await _db;
    await db.transaction((transaction) async {
      final songs = await transaction.query(
        'songs',
        columns: ['song_key'],
        where: 'id = ?',
        whereArgs: [songId],
        limit: 1,
      );
      if (songs.isEmpty) {
        throw StateError('A cifra $songId não foi encontrada.');
      }

      final currentKey = songs.first['song_key']! as String;
      final interval = songKeyInterval(currentKey, targetKey);
      if (interval != null && interval != 0) {
        final sections = await transaction.query(
          'sections',
          columns: ['id', 'measures'],
          where: 'song_id = ?',
          whereArgs: [songId],
        );
        for (final section in sections) {
          final measures = (jsonDecode(section['measures']! as String) as List)
              .cast<String>();
          await transaction.update(
            'sections',
            {
              'measures': jsonEncode(transposeMeasures(measures, interval)),
            },
            where: 'id = ?',
            whereArgs: [section['id']],
          );
        }
      }

      await transaction.update(
        'songs',
        {'song_key': targetKey},
        where: 'id = ?',
        whereArgs: [songId],
      );
    });
  }

  @override
  Future<void> deleteSong(int songId) async {
    final db = await _db;
    await db.delete('songs', where: 'id = ?', whereArgs: [songId]);
  }

  @override
  Future<void> addSection(int songId, NewSection section) async {
    final db = await _db;
    final currentSections = await db.query(
      'sections',
      columns: ['position'],
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'position DESC',
      limit: 1,
    );
    final position = currentSections.isEmpty
        ? 0
        : (currentSections.first['position']! as int) + 1;

    await db.insert('sections', {
      'song_id': songId,
      'title': section.title,
      'measures': jsonEncode(section.measures),
      'position': position,
    });
  }

  @override
  Future<void> deleteSection(int sectionId) async {
    final db = await _db;
    await db.delete('sections', where: 'id = ?', whereArgs: [sectionId]);
  }
}
