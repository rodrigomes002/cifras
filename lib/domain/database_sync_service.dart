enum DatabaseSyncAction { alreadySynced, uploadLocal, downloadDrive, conflict }

enum DatabaseSyncChoice { uploadLocal, downloadDrive }

enum DatabaseSyncResult { uploaded, downloaded, alreadySynced, cancelled }

DatabaseSyncAction determineDatabaseSyncAction({
  required String localHash,
  required String? driveHash,
  required String? lastSyncHash,
}) {
  if (driveHash == null) return DatabaseSyncAction.uploadLocal;
  if (localHash == driveHash) return DatabaseSyncAction.alreadySynced;
  if (lastSyncHash == null) return DatabaseSyncAction.conflict;
  if (localHash == lastSyncHash) return DatabaseSyncAction.downloadDrive;
  if (driveHash == lastSyncHash) return DatabaseSyncAction.uploadLocal;
  return DatabaseSyncAction.conflict;
}

abstract interface class DatabaseSyncService {
  Future<DatabaseSyncResult> synchronize({
    required Future<DatabaseSyncChoice?> Function({required bool isFirstSync})
    resolveConflict,
  });
}
