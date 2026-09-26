import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Thin wrapper around the local SQLite database.
///
/// Android uses the platform `sqflite` backend, every desktop platform is
/// served by `sqflite_common_ffi`, which ships its own SQLite build.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _version = 1;
  static const String _fileName = 'kora_ai.db';

  Database? _db;
  String? _pathOverride;
  static bool _ffiReady = false;

  /// Initialises the desktop SQLite backend exactly once per process.
  static void _ensureFfiFactory() {
    if (_ffiReady) return;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _ffiReady = true;
  }

  /// Points the database at an arbitrary path. Used by tests to run against
  /// an in-memory SQLite database.
  @visibleForTesting
  void useDatabasePath(String path) {
    _pathOverride = path;
    _db = null;
  }

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    final opened = await _open();
    _db = opened;
    return opened;
  }

  Future<Database> _open() async {
    final override = _pathOverride;
    final isMobile = Platform.isAndroid || Platform.isIOS;
    if (!isMobile || override != null) {
      _ensureFfiFactory();
    }
    String path;
    if (override != null) {
      path = override;
    } else {
      final dir = await getApplicationSupportDirectory();
      final file = File(p.join(dir.path, _fileName));
      await file.parent.create(recursive: true);
      path = file.path;
    }
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        document_ids TEXT NOT NULL DEFAULT '[]'
      )
    ''');
    batch.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        sources TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (conversation_id) REFERENCES conversations (id)
          ON DELETE CASCADE
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_messages_conversation ON messages (conversation_id, created_at)',
    );
    batch.execute('''
      CREATE TABLE documents (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        source_path TEXT,
        mime_type TEXT,
        size_bytes INTEGER NOT NULL DEFAULT 0,
        chunk_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        error TEXT,
        is_embedded INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE chunks (
        id TEXT PRIMARY KEY,
        document_id TEXT NOT NULL,
        ordinal INTEGER NOT NULL,
        content TEXT NOT NULL,
        tokens INTEGER NOT NULL DEFAULT 0,
        embedding BLOB,
        FOREIGN KEY (document_id) REFERENCES documents (id) ON DELETE CASCADE
      )
    ''');
    batch.execute('CREATE INDEX idx_chunks_document ON chunks (document_id)');
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Used by tests and by the "reset local data" action in settings.
  Future<void> wipe() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('chunks');
    batch.delete('documents');
    batch.delete('messages');
    batch.delete('conversations');
    await batch.commit(noResult: true);
  }
}
