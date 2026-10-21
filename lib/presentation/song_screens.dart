import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/database_sync_service.dart';
import '../domain/music_transposition.dart';
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

class SongLibraryScreen extends StatefulWidget {
  const SongLibraryScreen({
    super.key,
    required this.viewModel,
    this.databaseSyncService,
  });

  final SongLibraryViewModel viewModel;
  final DatabaseSyncService? databaseSyncService;

  @override
  State<SongLibraryScreen> createState() => _SongLibraryScreenState();
}

class _SongLibraryScreenState extends State<SongLibraryScreen> {
  String _search = '';
  bool _isSyncing = false;

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

  Future<void> _syncDatabase() async {
    final service = widget.databaseSyncService;
    if (service == null || _isSyncing) return;

    setState(() => _isSyncing = true);
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_sync_outlined),
                SizedBox(width: 12),
                Flexible(child: Text('Sincronizando com Google Drive...')),
              ],
            ),
          ),
        ),
      ),
    );
    DatabaseSyncResult? result;
    Object? syncError;
    try {
      result = await service.synchronize(
        resolveConflict: ({required isFirstSync}) =>
            showDialog<DatabaseSyncChoice>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text(
                  isFirstSync
                      ? 'Escolha o banco para sincronizar'
                      : 'As cifras foram alteradas nos dois lados',
                ),
                content: Text(
                  isFirstSync
                      ? 'Já existe um banco no Google Drive. Escolha qual versão manter.'
                      : 'Escolha qual versão manter. A outra será substituída.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      DatabaseSyncChoice.downloadDrive,
                    ),
                    child: const Text('Usar versão do Drive'),
                  ),
                  FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, DatabaseSyncChoice.uploadLocal),
                    child: const Text('Enviar versão local'),
                  ),
                ],
              ),
            ),
      );
      await widget.viewModel.load();
    } catch (error) {
      syncError = error;
      await widget.viewModel.load();
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() => _isSyncing = false);
      }
    }
    if (!mounted) return;
    if (syncError != null) {
      _showError('Não foi possível sincronizar com o Google Drive: $syncError');
      return;
    }
    final message = switch (result!) {
      DatabaseSyncResult.uploaded => 'Banco enviado ao Google Drive.',
      DatabaseSyncResult.downloaded => 'Banco restaurado do Google Drive.',
      DatabaseSyncResult.alreadySynced => 'O banco já está sincronizado.',
      DatabaseSyncResult.cancelled => null,
    };
    if (message != null) _showError(message);
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
          if (widget.databaseSyncService != null)
            IconButton(
              tooltip: 'Sincronizar com Google Drive',
              onPressed: _isSyncing ? null : _syncDatabase,
              icon: const Icon(Icons.cloud_sync_outlined),
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
        onPressed: _isSyncing ? null : _createSong,
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onDelete});

  final SongSection section;
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
  const _MeasureCard({required this.number, required this.chords});

  final int number;
  final String chords;

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
          Text(
            chords,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.forest,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
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
