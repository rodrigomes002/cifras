import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'data/google_drive_database_sync.dart';
import 'data/sqlite_song_repository.dart';
import 'domain/database_sync_service.dart';
import 'domain/song_repository.dart';
import 'presentation/song_library_view_model.dart';
import 'presentation/song_screens.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SqliteSongRepository();
  final databaseSyncService =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? GoogleDriveDatabaseSync(repository)
      : null;
  runApp(
    CifrasApp(repository: repository, databaseSyncService: databaseSyncService),
  );
}

class CifrasApp extends StatefulWidget {
  const CifrasApp({
    super.key,
    required this.repository,
    this.databaseSyncService,
  });

  final SongRepository repository;
  final DatabaseSyncService? databaseSyncService;

  @override
  State<CifrasApp> createState() => _CifrasAppState();
}

class _CifrasAppState extends State<CifrasApp> {
  late final SongLibraryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SongLibraryViewModel(widget.repository)..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cifras',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: SongLibraryScreen(
        viewModel: _viewModel,
        databaseSyncService: widget.databaseSyncService,
      ),
    );
  }
}
