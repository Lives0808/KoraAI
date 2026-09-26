import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

import '../../core/utils/text_utils.dart';

class ExtractedText {
  const ExtractedText(this.text, {this.warning});

  final String text;
  final String? warning;

  bool get isEmpty => text.trim().isEmpty;
}

/// Turns a file on disk into plain text.
///
/// Supported out of the box: PDF, DOCX, and every text-ish extension listed in
/// [plainTextExtensions]. Anything else is decoded as UTF-8 as a last resort.
class TextExtractor {
  const TextExtractor();

  static const Set<String> plainTextExtensions = <String>{
    'txt', 'text', 'md', 'markdown', 'mdx', 'rst', 'adoc',
    'json', 'jsonl', 'yaml', 'yml', 'toml', 'ini', 'cfg', 'env', 'properties',
    'csv', 'tsv', 'log',
    'xml', 'html', 'htm', 'xhtml', 'svg',
    'dart', 'py', 'js', 'jsx', 'ts', 'tsx', 'java', 'kt', 'kts', 'swift',
    'go', 'rs', 'rb', 'php', 'c', 'h', 'cc', 'cpp', 'hpp', 'cs', 'm', 'mm',
    'sh', 'bash', 'zsh', 'fish', 'ps1', 'bat', 'sql', 'graphql', 'proto',
    'r', 'jl', 'lua', 'pl', 'scala', 'vue', 'svelte', 'css', 'scss', 'less',
  };

  static const Set<String> binaryExtensions = <String>{'pdf', 'docx'};

  static List<String> get supportedExtensions =>
      <String>{...plainTextExtensions, ...binaryExtensions}.toList()..sort();

  Future<ExtractedText> extractBytes({
    required Uint8List bytes,
    required String name,
  }) async {
    final extension = p.extension(name).replaceFirst('.', '').toLowerCase();
    switch (extension) {
      case 'pdf':
        return _extractPdf(bytes);
      case 'docx':
        return _extractDocx(bytes);
      case 'doc':
        return const ExtractedText(
          '',
          warning: 'Legacy .doc files are not supported. Save as .docx or PDF.',
        );
      default:
        return ExtractedText(_decodeText(bytes));
    }
  }

  ExtractedText _extractPdf(Uint8List bytes) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final text = normalizeWhitespace(
        PdfTextExtractor(document).extractText(),
      );
      if (text.isEmpty) {
        return const ExtractedText(
          '',
          warning: 'No selectable text found — this PDF is probably a scan.',
        );
      }
      return ExtractedText(text);
    } on Exception catch (error) {
      return ExtractedText('', warning: 'Could not read PDF: $error');
    } finally {
      document?.dispose();
    }
  }

  ExtractedText _extractDocx(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final entry = archive.files.firstWhere(
        (file) => file.name == 'word/document.xml',
        orElse: () => throw const FormatException('missing word/document.xml'),
      );
      final xmlText = utf8.decode(
        entry.content as List<int>,
        allowMalformed: true,
      );
      final document = XmlDocument.parse(xmlText);
      final buffer = StringBuffer();
      for (final paragraph in document.findAllElements('w:p')) {
        final pieces = <String>[];
        for (final node in paragraph.descendants) {
          if (node is! XmlElement) continue;
          if (node.name.local == 't') {
            pieces.add(node.innerText);
          } else if (node.name.local == 'tab') {
            pieces.add('\t');
          } else if (node.name.local == 'br') {
            pieces.add('\n');
          }
        }
        final line = pieces.join().trim();
        if (line.isNotEmpty) buffer.writeln(line);
      }
      final text = normalizeWhitespace(buffer.toString());
      if (text.isEmpty) {
        return const ExtractedText('', warning: 'The document appears empty.');
      }
      return ExtractedText(text);
    } on Exception catch (error) {
      return ExtractedText('', warning: 'Could not read DOCX: $error');
    }
  }

  String _decodeText(Uint8List bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.contains('\u0000')) {
      // Very likely UTF-16 (common for Windows-exported .txt files).
      try {
        text = String.fromCharCodes(_utf16CodeUnits(bytes));
      } on Exception {
        // keep the UTF-8 result
      }
    }
    return normalizeWhitespace(text.replaceAll('\u0000', ''));
  }

  Iterable<int> _utf16CodeUnits(Uint8List bytes) sync* {
    final littleEndian = bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE;
    final start = (bytes.length >= 2 && (bytes[0] == 0xFF || bytes[0] == 0xFE))
        ? 2
        : 0;
    for (var i = start; i + 1 < bytes.length; i += 2) {
      yield littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1];
    }
  }
}
