import 'package:flutter/foundation.dart';

import '../domain/song.dart';
import '../domain/song_repository.dart';

class SongLibraryViewModel extends ChangeNotifier {
  SongLibraryViewModel(this._repository);

  final SongRepository _repository;
  List<Song> songs = const [];
  bool isLoading = true;
  Object? loadError;

  Future<void> load() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      songs = await _repository.getSongs();
    } catch (error) {
      loadError = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replaceSongs(List<Song> songs) async {
    await _repository.replaceSongs(songs);
    await load();
    if (loadError != null) {
      throw StateError(
        'Não foi possível atualizar a biblioteca após a importação.',
      );
    }
  }

  Future<void> addSong(NewSong song) async {
    await _repository.addSong(song);
    await load();
  }

  Future<void> changeSongKey(int songId, String key) async {
    await _repository.changeSongKey(songId, key);
    await load();
  }

  Future<void> setSongFavorite(int songId, bool isFavorite) async {
    await _repository.setSongFavorite(songId, isFavorite);
    await load();
  }

  Future<void> deleteSong(int songId) async {
    await _repository.deleteSong(songId);
    await load();
  }

  Future<void> addSection(int songId, NewSection section) async {
    await _repository.addSection(songId, section);
    await load();
  }

  Future<void> deleteSection(int sectionId) async {
    await _repository.deleteSection(sectionId);
    await load();
  }
}
