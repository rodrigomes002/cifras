import 'song.dart';

abstract interface class SongRepository {
  Future<List<Song>> getSongs();

  Future<void> addSong(NewSong song);

  Future<void> deleteSong(int songId);

  Future<void> addSection(int songId, NewSection section);

  Future<void> deleteSection(int sectionId);
}
