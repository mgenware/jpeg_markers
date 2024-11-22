import 'dart:math';
import 'dart:typed_data';

/// A class representing a JPEG marker.
class JpegMarker {
  /// The type byte of the marker.
  final int type;

  /// The segment size of the marker. -1 means unknown marker.
  final int segmentLength;

  /// The content size of the marker. Could be negative if segment length is invalid.
  int get contentLength => segmentLength - 2;

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
    return s;
  }
}

/// Scans the JPEG markers in the given data.
int scanJpegMarkers(
    Uint8List data, bool Function(JpegMarker marker, int offset) callback,
    {bool? continueOnNonMarkers}) {
  int offset = 0;
  while (offset < data.length) {
    final markerData = Uint8List.sublistView(data, offset);
    final marker = _parseMarker(markerData);
    var shouldContinue = true;
    if (marker != null) {
      shouldContinue = callback(marker, offset);
    }
    if (!shouldContinue) {
      break;
    }
    if (marker == null) {
      if (continueOnNonMarkers != true) {
        break;
      }
      offset = _nextMarkerIndex(data, offset + 1);
    } else if (marker.segmentLength >= 0) {
      // 2 is marker size.
      offset += 2 + marker.segmentLength;
    } else {
      // 2 is marker size.
      offset += 2 + _segmentLength(markerData);
    }
  }
  return min(offset, data.length);
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

  switch (data[1]) {
    case 0x00:
      return JpegMarker(data[1], 0, 'Reserved for JPEG extensions');

    case 0xc0:
      return JpegMarker(data[1], _segmentLength(data), 'SOF0 (Baseline)');

    case 0xc1:
      return JpegMarker(
          data[1], _segmentLength(data), 'SOF1 (Extended Sequential)');

    case 0xc2:
      return JpegMarker(data[1], _segmentLength(data), 'SOF2 (Progressive)');

    case 0xc3:
      return JpegMarker(data[1], _segmentLength(data), 'SOF3 (Lossless)');

    case 0xc4:
      return JpegMarker(data[1], _segmentLength(data), 'DHT');

    case 0xc5:
      return JpegMarker(
          data[1], _segmentLength(data), 'SOF5 (Differential Sequential)');

    case 0xc6:
      return JpegMarker(
          data[1], _segmentLength(data), 'SOF6 (Differential Progressive)');

    case 0xc7:
      return JpegMarker(
          data[1], _segmentLength(data), 'SOF7 (Differential Lossless)');

    case 0xc8:
      return JpegMarker(data[1], _segmentLength(data), 'JPG');

    case 0xc9:
      return JpegMarker(data[1], _segmentLength(data),
          'SOF9 (Extended Sequential, Arithmetic)');

    case 0xca:
      return JpegMarker(
          data[1], _segmentLength(data), 'SOF10 (Progressive, Arithmetic)');

    case 0xcb:
      return JpegMarker(
          data[1], _segmentLength(data), 'SOF11 (Lossless, Arithmetic)');

    case 0xcc:
      return JpegMarker(data[1], _segmentLength(data), 'DAC');

    case 0xcd:
      return JpegMarker(data[1], _segmentLength(data),
          'SOF13 (Differential Sequential, Arithmetic)');

    case 0xce:
      return JpegMarker(data[1], _segmentLength(data),
          'SOF14 (Differential Progressive, Arithmetic)');

    case 0xcf:
      return JpegMarker(data[1], _segmentLength(data),
          'SOF15 (Differential Lossless, Arithmetic)');

    case 0xd0:
    case 0xd1:
    case 0xd2:
    case 0xd3:
    case 0xd4:
    case 0xd5:
    case 0xd6:
    case 0xd7:
      return JpegMarker(data[1], 0, 'RST${data[1] - 0xd0}');

    case 0xd8:
      return JpegMarker(data[1], 0, 'SOI');

    case 0xd9:
      return JpegMarker(data[1], 0, 'EOI');

    case 0xda:
      final headersize = _segmentLength(data);
      final nextMarkerIndex = _nextMarkerIndex(data, headersize);
      return JpegMarker(data[1], nextMarkerIndex - 2, 'SOS');

    case 0xdb:
      return JpegMarker(data[1], _segmentLength(data), 'DQT');

    case 0xdc:
      return JpegMarker(data[1], _segmentLength(data), 'DNL');

    case 0xdd:
      return JpegMarker(data[1], 4, 'DRI');

    case 0xde:
      return JpegMarker(data[1], _segmentLength(data), 'DHP');

    case 0xdf:
      return JpegMarker(data[1], _segmentLength(data), 'EXP');

    case 0xe0:
      return JpegMarker(data[1], _segmentLength(data), 'JFIF');

    case 0xe1:
      return JpegMarker(data[1], _segmentLength(data), 'APP1');

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
      return JpegMarker(data[1], _segmentLength(data), 'APP${data[1] - 0xe0}');

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
      return JpegMarker(data[1], _segmentLength(data), 'JPG${data[1] - 0xf0}');

    case 0xfe:
      return JpegMarker(data[1], _segmentLength(data), 'Comment');

    default:
      return JpegMarker(data[1], -1, null);
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
