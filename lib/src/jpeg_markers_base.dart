import 'dart:math';
import 'dart:typed_data';

/// A class representing a JPEG marker.
class JpegMarker {
  /// The type byte of the marker.
  final int type;

  /// The segment size of the marker. -1 means unknown marker.
  final int segmentLength;

  int get markerLength => segmentLength + 2;

  /// The content size of the marker. Could be negative if segment length is invalid.
  int get contentLength => segmentLength <= 0 ? 0 : segmentLength - 2;

  /// null means unknown marker.
  final String? description;

  JpegMarker(this.type, this.segmentLength, this.description);

  @override
  String toString() {
    final hexType = '0x${type.toRadixString(16).toUpperCase()}';
    String s = hexType;
    s += '(${description ?? 'Unknown'})';
    if (segmentLength >= 0) {
      s += ' | Size: $segmentLength';
    }
    if (contentLength > 0) {
      s += ' | Content size: $contentLength';
    }
    return s;
  }
}

class JpegMarkerWithOffset {
  final int offset;
  final JpegMarker marker;

  JpegMarkerWithOffset(this.offset, this.marker);

  @override
  String toString() => '[$offset]: $marker';
}

abstract class JpegSection {
  final int offset;
  final int length;

  JpegSection(this.offset, this.length);
}

class JpegDataSection extends JpegSection {
  final int dataIndex;

  JpegDataSection(super.offset, super.length, this.dataIndex);

  @override
  String toString() => 'JpegDataSection($dataIndex)[$offset]\n$length';
}

class JpegImgSection extends JpegSection {
  final List<JpegMarkerWithOffset> markers;
  final int imgIndex;

  JpegImgSection(super.offset, super.length, this.markers, this.imgIndex);

  @override
  String toString() =>
      'JpegImgSection($imgIndex)[$offset]\n$length\nMarkers: \n${markers.join('\n')}';
}

/// Scans the JPEG markers in the given data.
int scanJpegMarkers(
  Uint8List data,
  void Function(JpegMarker marker, int offset) callback,
) {
  int offset = 0;
  while (offset < data.length) {
    final markerData = Uint8List.sublistView(data, offset);
    final marker = _parseMarker(markerData);
    if (marker != null) {
      callback(marker, offset);
    }
    if (marker == null) {
      break;
    } else if (marker.segmentLength >= 0) {
      // 2 is marker type size.
      offset += 2 + marker.segmentLength;
    } else {
      // 2 is marker type size.
      offset += 2 + _segmentLength(markerData);
    }
  }
  return min(offset, data.length);
}

// (nextOffset, isSOI)
(int, bool) _nextChunkOffset(Uint8List data, int start) {
  if (data.isEmpty || start >= data.length - 1) {
    return (-1, false);
  }
  // Find the next SOI.
  for (int i = start; i < data.length - 1; i++) {
    final cur = data[i];
    final next = data[i + 1];
    if (cur == 0xff && next == 0xd8) {
      return (i, true);
    }
  }
  return (data.length, false);
}

List<JpegSection> scanJpegSections(
  Uint8List data,
) {
  final List<JpegSection> res = [];
  var gOffset = 0;

  var imgIndex = -1;
  var dataIndex = -1;

  void addAndMergeDataSection(int offset, int length) {
    if (length <= 0) {
      return;
    }
    if (res.isNotEmpty && res.last is JpegDataSection) {
      final last = res.last as JpegDataSection;
      if (last.offset + last.length == offset) {
        // Merge
        res[res.length - 1] = JpegDataSection(
          last.offset,
          last.length + length,
          last.dataIndex,
        );
        return;
      }
    }
    res.add(JpegDataSection(offset, length, ++dataIndex));
  }

  void flushMarkers(List<JpegMarkerWithOffset> markers) {
    final startOffset = markers.first.offset;
    final endOffset = markers.last.offset + markers.last.marker.markerLength;
    final totalLength = endOffset - startOffset;
    res.add(
      JpegImgSection(
        startOffset,
        totalLength,
        markers,
        ++imgIndex,
      ),
    );
  }

  while (true) {
    final (nextSOIOffset, isSOI) = _nextChunkOffset(data, gOffset);
    if (nextSOIOffset < 0) {
      break;
    }

    // Handle data before the next SOI.
    if (nextSOIOffset > gOffset) {
      addAndMergeDataSection(gOffset, nextSOIOffset - gOffset);
    }
    gOffset = nextSOIOffset;

    if (isSOI) {
      // SOI
      final possibleMarkers = <JpegMarkerWithOffset>[];
      final soiData = Uint8List.sublistView(data, gOffset);
      final localEndOffset = scanJpegMarkers(
        soiData,
        (marker, localOffset) {
          possibleMarkers.add(
            JpegMarkerWithOffset(gOffset + localOffset, marker),
          );
        },
      );
      final lastMarker = possibleMarkers.isNotEmpty
          ? possibleMarkers.last
          : null;
      if (lastMarker != null && lastMarker.marker.type == 0xd9) {
        // EOI
        flushMarkers(possibleMarkers);
        gOffset += localEndOffset;
      } else {
        // No EOI, discard all markers. Treat as data.
        addAndMergeDataSection(gOffset, localEndOffset);
        gOffset += localEndOffset;
      }
    } else {
      break;
    }
  }
  return res;
}

int _segmentLength(Uint8List data) {
  try {
    return data[2] * 256 + data[3];
  } catch (e) {
    throw Exception('Error parsing content size: $e');
  }
}

JpegMarker? _parseMarker(Uint8List data) {
  if (data.length < 2) {
    return null;
  }
  if (data[0] != 0xff) {
    return null;
  }

  final type = data[1];
  switch (type) {
    case 0x00:
      return JpegMarker(type, 0, 'Reserved');

    case 0x01:
      return JpegMarker(type, 0, 'TEM');

    case 0xc0:
      return JpegMarker(type, _segmentLength(data), 'SOF0 (Baseline)');

    case 0xc1:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF1 (Extended Sequential)',
      );

    case 0xc2:
      return JpegMarker(type, _segmentLength(data), 'SOF2 (Progressive)');

    case 0xc3:
      return JpegMarker(type, _segmentLength(data), 'SOF3 (Lossless)');

    case 0xc4:
      return JpegMarker(type, _segmentLength(data), 'DHT');

    case 0xc5:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF5 (Differential Sequential)',
      );

    case 0xc6:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF6 (Differential Progressive)',
      );

    case 0xc7:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF7 (Differential Lossless)',
      );

    case 0xc8:
      return JpegMarker(type, _segmentLength(data), 'JPG');

    case 0xc9:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF9 (Extended Sequential, Arithmetic)',
      );

    case 0xca:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF10 (Progressive, Arithmetic)',
      );

    case 0xcb:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF11 (Lossless, Arithmetic)',
      );

    case 0xcc:
      return JpegMarker(type, _segmentLength(data), 'DAC');

    case 0xcd:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF13 (Differential Sequential, Arithmetic)',
      );

    case 0xce:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF14 (Differential Progressive, Arithmetic)',
      );

    case 0xcf:
      return JpegMarker(
        type,
        _segmentLength(data),
        'SOF15 (Differential Lossless, Arithmetic)',
      );

    case 0xd0:
    case 0xd1:
    case 0xd2:
    case 0xd3:
    case 0xd4:
    case 0xd5:
    case 0xd6:
    case 0xd7:
      return JpegMarker(type, 0, 'RST${type - 0xd0}');

    case 0xd8:
      return JpegMarker(type, 0, 'SOI');

    case 0xd9:
      return JpegMarker(type, 0, 'EOI');

    case 0xda:
      final headersize = _segmentLength(data);
      final nextMarkerIndex = _nextMarkerIndex(data, headersize);
      return JpegMarker(type, nextMarkerIndex - 2, 'SOS');

    case 0xdb:
      return JpegMarker(type, _segmentLength(data), 'DQT');

    case 0xdc:
      return JpegMarker(type, _segmentLength(data), 'DNL');

    case 0xdd:
      return JpegMarker(type, 4, 'DRI');

    case 0xde:
      return JpegMarker(type, _segmentLength(data), 'DHP');

    case 0xdf:
      return JpegMarker(type, _segmentLength(data), 'EXP');

    case 0xe0:
      return JpegMarker(type, _segmentLength(data), 'APP0');

    case 0xe1:
      return JpegMarker(type, _segmentLength(data), 'APP1');

    case 0xe2:
    case 0xe3:
    case 0xe4:
    case 0xe5:
    case 0xe6:
    case 0xe7:
    case 0xe8:
    case 0xe9:
    case 0xea:
    case 0xeb:
    case 0xec:
    case 0xed:
    case 0xee:
    case 0xef:
      return JpegMarker(type, _segmentLength(data), 'APP${type - 0xe0}');

    case 0xf0:
    case 0xf1:
    case 0xf2:
    case 0xf3:
    case 0xf4:
    case 0xf5:
    case 0xf6:
    case 0xf7:
    case 0xf8:
    case 0xf9:
    case 0xfa:
    case 0xfb:
    case 0xfc:
    case 0xfd:
      return JpegMarker(type, _segmentLength(data), 'JPG${type - 0xf0}');

    case 0xfe:
      return JpegMarker(type, _segmentLength(data), 'Comment');

    default:
      return JpegMarker(type, -1, null);
  }
}

int _nextMarkerIndex(Uint8List data, int startIndex) {
  int offset = startIndex;
  while (offset < data.length - 1) {
    final cur = data[offset];
    final next = data[offset + 1];
    if (cur == 0xff &&
        next != 0x00 &&
        next != 0xd0 &&
        next != 0xd1 &&
        next != 0xd2 &&
        next != 0xd3 &&
        next != 0xd4 &&
        next != 0xd5 &&
        next != 0xd6 &&
        next != 0xd7 &&
        next != 0xd8) {
      break;
    }
    offset++;
  }
  return offset;
}
