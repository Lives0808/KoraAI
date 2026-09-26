import '../../core/utils/text_utils.dart';

/// Splits long documents into overlapping, paragraph-aware chunks.
class TextChunker {
  const TextChunker({
    this.maxChars = 1000,
    this.overlapChars = 150,
    this.minChars = 40,
  });

  final int maxChars;
  final int overlapChars;

  /// Chunks shorter than this are merged into the previous one when possible.
  final int minChars;

  List<String> split(String raw) {
    final text = normalizeWhitespace(raw);
    if (text.isEmpty) return const <String>[];

    final segments = <String>[];
    for (final paragraph in text.split(RegExp(r'\n{2,}'))) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length <= maxChars) {
        segments.add(trimmed);
      } else {
        segments.addAll(_splitLongParagraph(trimmed));
      }
    }

    final chunks = <String>[];
    var buffer = StringBuffer();

    void flush() {
      final value = buffer.toString().trim();
      if (value.isNotEmpty) chunks.add(value);
      buffer = StringBuffer();
    }

    for (final segment in segments) {
      if (buffer.isEmpty) {
        buffer.write(segment);
        continue;
      }
      if (buffer.length + segment.length + 2 > maxChars) {
        flush();
        final previous = chunks.isEmpty ? '' : chunks.last;
        final carry = _tail(previous);
        if (carry.isNotEmpty) buffer.write('$carry\n\n');
        buffer.write(segment);
      } else {
        buffer.write('\n\n$segment');
      }
    }
    flush();

    return _coalesce(chunks);
  }

  List<String> _coalesce(List<String> chunks) {
    if (chunks.length < 2) return chunks;
    final result = <String>[];
    for (final chunk in chunks) {
      if (result.isNotEmpty && chunk.length < minChars) {
        final merged = '${result.last}\n\n$chunk';
        if (merged.length <= maxChars + minChars) {
          result[result.length - 1] = merged;
          continue;
        }
      }
      result.add(chunk);
    }
    return result;
  }

  List<String> _splitLongParagraph(String paragraph) {
    final pieces = <String>[];
    final sentences = paragraph.split(_sentenceBoundary);
    var buffer = StringBuffer();
    for (final sentence in sentences) {
      final value = sentence.trim();
      if (value.isEmpty) continue;
      if (value.length > maxChars) {
        if (buffer.isNotEmpty) {
          pieces.add(buffer.toString().trim());
          buffer = StringBuffer();
        }
        pieces.addAll(_hardSplit(value));
        continue;
      }
      if (buffer.isNotEmpty && buffer.length + value.length + 1 > maxChars) {
        pieces.add(buffer.toString().trim());
        buffer = StringBuffer();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(value);
    }
    final tail = buffer.toString().trim();
    if (tail.isNotEmpty) pieces.add(tail);
    return pieces;
  }

  List<String> _hardSplit(String value) {
    final pieces = <String>[];
    final step = maxChars - overlapChars;
    for (var start = 0; start < value.length; start += step) {
      final end = (start + maxChars).clamp(0, value.length);
      pieces.add(value.substring(start, end));
      if (end == value.length) break;
    }
    return pieces;
  }

  String _tail(String previous) {
    if (previous.isEmpty || overlapChars <= 0) return '';
    final start = previous.length - overlapChars;
    final slice = start <= 0 ? previous : previous.substring(start);
    // Start the overlap at a sentence boundary when one is close by.
    final match = _sentenceBoundary.allMatches(slice).toList();
    if (match.isNotEmpty && match.first.end < slice.length - 8) {
      return slice.substring(match.first.end).trim();
    }
    final space = slice.indexOf(' ');
    if (space > 0 && space < 40) return slice.substring(space + 1).trim();
    return slice.trim();
  }

  static final RegExp _sentenceBoundary =
      RegExp(r'(?<=[。！？!?；;\.])\s*|(?<=\n)');
}
