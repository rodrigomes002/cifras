import 'song.dart';
import 'song_backup.dart';

abstract interface class SongRepository {
  Future<List<Song>> getSongs();

  Future<void> replaceSongs(List<Song> songs);

  Future<void> replaceBackup(SongBackup backup);

  Future<void> addSong(NewSong song);

  Future<void> changeSongKey(int songId, String key);

  Future<void> setSongFavorite(int songId, bool isFavorite);

  Future<void> deleteSong(int songId);

  Future<void> addSection(int songId, NewSection section);

  Future<void> updateSection(int sectionId, NewSection section);

  Future<void> deleteSection(int sectionId);

  Future<List<GuitarChordShape>> getChordShapes(String chord);

  Future<void> saveChordShapes(String chord, List<GuitarChordShape> shapes);

  Future<Map<String, List<GuitarChordShape>>> getSavedChordShapes();

  Future<List<String>> getCustomChords();

  Future<void> saveCustomChord(String chord);
}
