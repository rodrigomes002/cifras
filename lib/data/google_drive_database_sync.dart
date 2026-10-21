import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/database_sync_service.dart';
import 'sqlite_song_repository.dart';

const _driveScopes = [drive.DriveApi.driveFileScope];
const _backupName = 'cifras.db';
const _serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

class GoogleDriveDatabaseSync implements DatabaseSyncService {
  GoogleDriveDatabaseSync(this._repository);

  final SqliteSongRepository _repository;
  final Future<void> _initialization = GoogleSignIn.instance.initialize(
    serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
  );

  @override
  Future<DatabaseSyncResult> synchronize({
    required Future<DatabaseSyncChoice?> Function({required bool isFirstSync})
    resolveConflict,
  }) async {
    if (_serverClientId.isEmpty) {
      throw StateError(
        'Configure GOOGLE_SERVER_CLIENT_ID com o client ID OAuth Web '
        'antes de sincronizar.',
      );
    }
    await _initialization;
    final signIn = GoogleSignIn.instance;
    final lightweightAttempt = signIn.attemptLightweightAuthentication();
    final account =
        (lightweightAttempt == null ? null : await lightweightAttempt) ??
        await signIn.authenticate();
    final authorization =
        await account.authorizationClient.authorizationForScopes(
          _driveScopes,
        ) ??
        await account.authorizationClient.authorizeScopes(_driveScopes);
    final client = authorization.authClient(scopes: _driveScopes);

    try {
      final driveApi = drive.DriveApi(client);
      final driveFile = await _findBackup(driveApi);
      await _repository.closeDatabase();

      final localFile = File(await _repository.databasePath);
      final localHash = await _hash(localFile);
      final preferences = await SharedPreferences.getInstance();
      final syncKey = 'drive_sync_hash_${account.id}';
      final lastSyncHash = preferences.getString(syncKey);
      final driveHash = driveFile?.md5Checksum;

      if (driveFile != null && driveHash == null) {
        throw StateError('O Drive não informou o checksum do banco de dados.');
      }

      final action = determineDatabaseSyncAction(
        localHash: localHash,
        driveHash: driveHash,
        lastSyncHash: lastSyncHash,
      );

      if (action == DatabaseSyncAction.alreadySynced) {
        await _saveSyncHash(preferences, syncKey, localHash);
        return DatabaseSyncResult.alreadySynced;
      }

      final choice = switch (action) {
        DatabaseSyncAction.uploadLocal => DatabaseSyncChoice.uploadLocal,
        DatabaseSyncAction.downloadDrive => DatabaseSyncChoice.downloadDrive,
        DatabaseSyncAction.conflict => await resolveConflict(
          isFirstSync: lastSyncHash == null,
        ),
        DatabaseSyncAction.alreadySynced => null,
      };
      if (choice == null) return DatabaseSyncResult.cancelled;

      if (choice == DatabaseSyncChoice.uploadLocal) {
        await _upload(driveApi, driveFile, localFile);
        await _saveSyncHash(preferences, syncKey, localHash);
        return DatabaseSyncResult.uploaded;
      }

      final fileId = driveFile?.id;
      if (fileId == null) {
        throw StateError(
          'O backup no Google Drive não possui um identificador.',
        );
      }
      final downloadedFile = await _download(driveApi, fileId);
      try {
        final downloadedHash = await _hash(downloadedFile);
        if (downloadedHash != driveHash) {
          throw StateError('O arquivo baixado do Drive está incompleto.');
        }
        await _repository.replaceDatabase(downloadedFile);
        await _saveSyncHash(preferences, syncKey, downloadedHash);
      } finally {
        await downloadedFile.delete();
      }
      return DatabaseSyncResult.downloaded;
    } finally {
      client.close();
    }
  }

  Future<drive.File?> _findBackup(drive.DriveApi driveApi) async {
    final response = await driveApi.files.list(
      q: "name = '$_backupName' and trashed = false",
      spaces: 'drive',
      pageSize: 2,
      $fields: 'files(id,name,md5Checksum)',
    );
    final files = response.files ?? const <drive.File>[];
    if (files.length > 1) {
      throw StateError(
        'Há mais de um arquivo $_backupName no Google Drive. '
        'Remova os backups duplicados e tente novamente.',
      );
    }
    return files.isEmpty ? null : files.single;
  }

  Future<void> _upload(
    drive.DriveApi driveApi,
    drive.File? existingFile,
    File localFile,
  ) async {
    final media = drive.Media(localFile.openRead(), await localFile.length());
    if (existingFile == null) {
      await driveApi.files.create(
        drive.File()..name = _backupName,
        uploadMedia: media,
      );
      return;
    }

    final fileId = existingFile.id;
    if (fileId == null) {
      throw StateError('O backup no Google Drive não possui um identificador.');
    }
    await driveApi.files.update(drive.File(), fileId, uploadMedia: media);
  }

  Future<File> _download(drive.DriveApi driveApi, String fileId) async {
    final file = File(
      path.join(
        Directory.systemTemp.path,
        'cifras_${DateTime.now().microsecondsSinceEpoch}.db',
      ),
    );
    try {
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      if (response is! drive.Media) {
        throw StateError('O Drive retornou um arquivo sem conteúdo binário.');
      }
      await response.stream.pipe(file.openWrite());
      return file;
    } catch (_) {
      if (await file.exists()) await file.delete();
      rethrow;
    }
  }

  Future<String> _hash(File file) async {
    if (!await file.exists()) {
      throw FileSystemException(
        'O arquivo do banco de dados não existe.',
        file.path,
      );
    }
    return (await md5.bind(file.openRead()).first).toString();
  }

  Future<void> _saveSyncHash(
    SharedPreferences preferences,
    String key,
    String hash,
  ) async {
    if (!await preferences.setString(key, hash)) {
      throw StateError('Não foi possível salvar o estado da sincronização.');
    }
  }
}
