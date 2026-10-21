import 'package:flutter/material.dart';

import 'data/sqlite_song_repository.dart';
import 'domain/song_repository.dart';
import 'presentation/song_library_view_model.dart';
import 'presentation/song_screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CifrasApp(repository: SqliteSongRepository()));
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
    const seed = Color(0xFF315C4D);
    return MaterialApp(
      title: 'Cifras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          surface: const Color(0xFFF7F7F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7F2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F2),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE5E8E2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: seed, width: 1.5),
          ),
        ),
      ),
      home: SongLibraryScreen(viewModel: _viewModel),
    );
  }
}
