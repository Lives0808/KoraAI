import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/config/app_settings.dart';
import '../../data/db/document_repository.dart';
import '../../data/ingestion/document_indexer.dart';
import '../../data/ingestion/text_extractor.dart';
import '../../data/models/kora_document.dart';
import '../../data/retrieval/retriever.dart';

class DocumentsController extends ChangeNotifier {
  DocumentsController({
    DocumentRepository? repository,
    DocumentIndexer? indexer,
    Retriever? retriever,
  })  : _repository = repository ?? DocumentRepository(),
        _indexer = indexer ?? DocumentIndexer(),
        _retriever = retriever ?? Retriever();

  final DocumentRepository _repository;
  final DocumentIndexer _indexer;
  final Retriever _retriever;

  AppSettings _settings = const AppSettings();

  List<KoraDocument> _documents = const <KoraDocument>[];
  bool _loading = false;
  bool _importing = false;
  String? _lastError;
  double _progress = 0;

  List<KoraDocument> get documents => _documents;
  bool get isLoading => _loading;
  bool get isImporting => _importing;
  String? get lastError => _lastError;
  double get progress => _progress;

  List<KoraDocument> get readyDocuments =>
      _documents.where((document) => document.isReady).toList(growable: false);

  /// Called by the provider wiring whenever settings change.
  ///
  /// Deliberately does not notify listeners: it runs during a build.
  void bindSettings(AppSettings settings) {
    _settings = settings;
  }

  void clearError() {
    if (_lastError == null) return;
    _lastError = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _documents = await _repository.list();
    _loading = false;
    notifyListeners();
  }

  Future<void> importWithPicker() async {
    if (_importing) return;
    _lastError = null;
    try {
      final files = await FilePicker.pickFiles(
        dialogTitle: 'Import documents',
        type: FileType.custom,
        allowedExtensions: TextExtractor.supportedExtensions,
      );
      if (files.isEmpty) return;
      for (final file in files) {
        final bytes = await file.readAsBytes();
        await _ingest(
          name: file.name,
          bytes: bytes,
          sourcePath: file.path,
        );
      }
    } on Object catch (error) {
      _lastError = '$error';
    }
    await load();
  }

  Future<void> importText({required String title, required String text}) async {
    if (_importing) return;
    _lastError = null;
    _importing = true;
    _progress = 0;
    notifyListeners();
    try {
      final name = title.trim().isEmpty
          ? 'Note ${DateTime.now().toIso8601String().substring(0, 16)}'
          : title.trim();
      await _indexer.importText(
        title: name,
        text: text,
        settings: _settings,
        onChanged: (_) {},
      );
    } on Object catch (error) {
      _lastError = '$error';
    }
    _importing = false;
    await load();
  }

  Future<void> delete(KoraDocument document) async {
    await _repository.delete(document.id);
    _retriever.invalidate();
    await load();
  }

  Future<void> reindex(KoraDocument document) async {
    _lastError = null;
    _importing = true;
    _progress = 0;
    notifyListeners();
    try {
      await _indexer.reindex(
        document: document,
        settings: _settings,
        onChanged: _replaceLocally,
      );
      _retriever.invalidate();
    } on Object catch (error) {
      _lastError = '$error';
    }
    _importing = false;
    await load();
  }

  Future<void> embed(KoraDocument document) async {
    if (!_settings.embeddingsEnabled) {
      _lastError = 'Configure an embedding model in Settings first.';
      notifyListeners();
      return;
    }
    _lastError = null;
    _importing = true;
    _progress = 0;
    notifyListeners();
    try {
      await _indexer.embedDocument(
        document: document,
        settings: _settings,
        onProgress: (value) {
          _progress = value;
          notifyListeners();
        },
        onError: (message) => _lastError = message,
      );
      _retriever.invalidate();
    } on Object catch (error) {
      _lastError = '$error';
    }
    _importing = false;
    await load();
  }

  Future<void> _ingest({
    required String name,
    required Uint8List bytes,
    String? sourcePath,
  }) async {
    _importing = true;
    _progress = 0;
    notifyListeners();
    try {
      await _indexer.importBytes(
        name: name,
        bytes: bytes,
        settings: _settings,
        sourcePath: sourcePath,
        mimeType: _guessMimeType(name),
        onChanged: _replaceLocally,
      );
      _retriever.invalidate();
    } on Object catch (error) {
      _lastError = 'Failed to import $name: $error';
    }
    _importing = false;
    notifyListeners();
  }

  void _replaceLocally(KoraDocument document) {
    final next = <KoraDocument>[..._documents];
    final index = next.indexWhere((item) => item.id == document.id);
    if (index >= 0) {
      next[index] = document;
    } else {
      next.insert(0, document);
    }
    _documents = next;
    notifyListeners();
  }

  String? _guessMimeType(String name) {
    switch (p.extension(name).replaceFirst('.', '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'md':
        return 'text/markdown';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      default:
        return 'text/plain';
    }
  }
}
