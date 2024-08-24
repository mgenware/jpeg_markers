import 'dart:typed_data';

/// A class representing a JPEG marker.
class JpegMarker {
  /// The type byte of the marker.
  final int type;

  /// The content size of the marker. -1 means unknown marker.
  final int contentSize;

  /// null means unknown marker.
  final String? description;

  /// Extra information about the marker.
  final Map<String, dynamic>? extra;

  JpegMarker(this.type, this.contentSize, this.description, {this.extra});

  @override
  String toString() {
    final extraStr = extra?.entries.map((e) => '${e.key}: ${e.value}');
    final hexType = '0x${type.toRadixString(16).toUpperCase()}';
    String s = hexType;
    s += '(${description ?? 'Unknown'})';
    if (contentSize >= 0) {
      s += ' | Size: $contentSize';
    }
    if (extraStr != null) {
      s += ' | Extra: {${extraStr.join(', ')}}';
    }
    return s;
  }
}

/// Scans the JPEG markers in the given data.
void scanJpegMarkers(
    Uint8List data, bool Function(JpegMarker marker, int offset) callback) {
  int offset = 0;
  while (offset < data.length) {
    final markerData = data.sublist(offset);
    final marker = _showMarkers(markerData);
    var shouldContinue = true;
    if (marker != null) {
      shouldContinue = callback(marker, offset);
    }
    if (!shouldContinue) {
      break;
    }
    if (marker != null && marker.contentSize >= 0) {
      offset += 2 + marker.contentSize;
    } else {
      offset += 2 + _contentSize(markerData);
    }
  }
}

int _contentSize(Uint8List data) {
  return data[2] * 256 + data[3];
}

JpegMarker? _showMarkers(Uint8List data) {
  if (data[0] != 0xff) {
    return null;
  }

  switch (data[1]) {
    case 0xc0:
      return JpegMarker(
          data[1], _contentSize(data), 'Start of Frame (baseline)');

    case 0xc1:
      return JpegMarker(
          data[1], _contentSize(data), 'Start of Frame (extended sequential)');

    case 0xc2:
      return JpegMarker(
          data[1], _contentSize(data), 'Start of Frame (progressive)',
          extra: {
            'P': data[4],
            'Y': 256 * data[5] + data[6],
            'X': 256 * data[7] + data[8],
            'Nf': data[9],
          });

    case 0xc3:
      return JpegMarker(
          data[1], _contentSize(data), 'Start of Frame (lossless)');

    case 0xc4:
      return JpegMarker(data[1], _contentSize(data), 'Define Huffman');

    case 0xd0:
    case 0xd1:
    case 0xd2:
    case 0xd3:
    case 0xd4:
    case 0xd5:
    case 0xd6:
    case 0xd7:
      return JpegMarker(data[1], 0, 'Restart');

    case 0xd8:
      return JpegMarker(data[1], 0, 'SOI');

    case 0xd9:
      return JpegMarker(data[1], 0, 'End of Image');

    case 0xda:
      final headersize = _contentSize(data);
      int offset = headersize;
      while (true) {
        if (data[offset] == 0xff && data[offset + 1] != 0x00) {
          break;
        }
        offset++;
      }
      return JpegMarker(data[1], offset - 2, 'Start of Scan', extra: {
        'NC': data[4],
        'size': offset - headersize,
      });

    case 0xdb:
      return JpegMarker(data[1], _contentSize(data), 'Define Quantization');

    case 0xdd:
      return JpegMarker(data[1], 4, 'Define Restart Interval');

    case 0xe0:
      return JpegMarker(data[1], _contentSize(data), 'JFIF', extra: {
        'V': 256 * data[8] + data[9],
        'U': '${data[10]}/${data[11]}',
        'Xd': 256 * data[12] + data[13],
        'Yd': 256 * data[14] + data[15],
        'Xt': data[16],
        'Yt': data[17],
      });

    case 0xe1:
      return JpegMarker(data[1], _contentSize(data), 'APP1');

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
      return JpegMarker(data[1], _contentSize(data), 'APP${data[1] - 0xe0}');

    case 0xfe:
      return JpegMarker(data[1], _contentSize(data), 'Comment');

    default:
      return JpegMarker(data[1], -1, null);
  }
}
