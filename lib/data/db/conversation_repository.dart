
import '../../core/utils/ids.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import 'app_database.dart';

class ConversationRepository {
  ConversationRepository({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Conversation>> list() async {
    final db = await _database.database;
    final rows = await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Conversation.fromRow).toList(growable: false);
  }

  Future<Conversation> create({String? title}) async {
    final now = DateTime.now();
    final conversation = Conversation(
      id: newId(),
      title: title ?? '',
      createdAt: now,
      updatedAt: now,
    );
    final db = await _database.database;
    await db.insert('conversations', conversation.toRow());
    return conversation;
  }

  Future<void> save(Conversation conversation) async {
    final db = await _database.database;
    await db.update(
      'conversations',
      conversation.toRow(),
      where: 'id = ?',
      whereArgs: <Object?>[conversation.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('conversations', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> touch(String id, {String? title}) async {
    final db = await _database.database;
    final values = <String, Object?>{
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    if (title != null) values['title'] = title;
    await db.update('conversations', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ChatMessage>> messages(String conversationId) async {
    final db = await _database.database;
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessage.fromRow).toList(growable: false);
  }

  Future<void> insertMessage(ChatMessage message) async {
    final db = await _database.database;
    final values = message.toRow();
    final updated = await db.update(
      'messages',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[message.id],
    );
    if (updated == 0) {
      await db.insert('messages', values);
    }
  }

  Future<void> deleteMessage(String id) async {
    final db = await _database.database;
    await db.delete('messages', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteMessagesFrom(String conversationId, DateTime from) async {
    final db = await _database.database;
    await db.delete(
      'messages',
      where: 'conversation_id = ? AND created_at >= ?',
      whereArgs: <Object?>[conversationId, from.millisecondsSinceEpoch],
    );
  }
}
