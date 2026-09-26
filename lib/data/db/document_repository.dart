
import '../models/doc_chunk.dart';
import '../models/kora_document.dart';
import 'app_database.dart';

class DocumentRepository {
  DocumentRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<KoraDocument>> list() async {
    final db = await _database.database;
    final rows = await db.query('documents', orderBy: 'created_at DESC');
    return rows.map(KoraDocument.fromRow).toList(growable: false);
  }

  Future<KoraDocument?> find(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'documents',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return KoraDocument.fromRow(rows.first);
  }

  Future<List<KoraDocument>> findMany(List<String> ids) async {
    if (ids.isEmpty) return const <KoraDocument>[];
    final db = await _database.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'documents',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    return rows.map(KoraDocument.fromRow).toList(growable: false);
  }

  /// Inserts or updates a document row.
  ///
  /// Deliberately not `ConflictAlgorithm.replace`: replacing a parent row in
  /// SQLite deletes it first, which would cascade into `chunks` and silently
  /// throw away the whole index.
  Future<void> upsert(KoraDocument document) async {
    final db = await _database.database;
    final values = document.toRow();
    final updated = await db.update(
      'documents',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[document.id],
    );
    if (updated == 0) {
      await db.insert('documents', values);
    }
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('documents', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Replaces every chunk of [documentId] in a single transaction.
  Future<void> replaceChunks(String documentId, List<DocChunk> chunks) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.delete(
        'chunks',
        where: 'document_id = ?',
        whereArgs: <Object?>[documentId],
      );
      final batch = txn.batch();
      for (final chunk in chunks) {
        batch.insert('chunks', chunk.toRow());
      }
      await batch.commit(noResult: true);
    });
  }

  /// Persists embeddings without touching the chunk text.
  Future<void> saveEmbeddings(List<DocChunk> chunks) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final chunk in chunks) {
        batch.update(
          'chunks',
          <String, Object?>{'embedding': chunk.embeddingBytes},
          where: 'id = ?',
          whereArgs: <Object?>[chunk.id],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<DocChunk>> chunksOf(String documentId) async {
    final db = await _database.database;
    final rows = await db.query(
      'chunks',
      where: 'document_id = ?',
      whereArgs: <Object?>[documentId],
      orderBy: 'ordinal ASC',
    );
    return rows.map(DocChunk.fromRow).toList(growable: false);
  }

  Future<List<DocChunk>> chunksOfMany(List<String> documentIds) async {
    if (documentIds.isEmpty) return const <DocChunk>[];
    final db = await _database.database;
    final placeholders = List.filled(documentIds.length, '?').join(',');
    final rows = await db.query(
      'chunks',
      where: 'document_id IN ($placeholders)',
      whereArgs: documentIds,
      orderBy: 'document_id ASC, ordinal ASC',
    );
    return rows.map(DocChunk.fromRow).toList(growable: false);
  }

  Future<int> countChunks() async {
    final db = await _database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM chunks');
    if (rows.isEmpty) return 0;
    final value = rows.first['c'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
