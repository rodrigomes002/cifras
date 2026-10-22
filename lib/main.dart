import 'package:flutter/material.dart';

import 'data/sqlite_song_repository.dart';
import 'domain/song_repository.dart';
import 'presentation/song_library_view_model.dart';
import 'presentation/song_screens.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = SqliteSongRepository();
  runApp(CifrasApp(repository: repository));
}

class CifrasApp extends StatefulWidget {
  const CifrasApp({super.key, required this.repository});

  final SongRepository repository;

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
      home: SongLibraryScreen(viewModel: _viewModel),
    );
  }
}
