import 'dart:typed_data';

/// A class representing a JPEG marker.
class JpegMarker {
  /// The type byte of the marker.
  final int type;

  /// The size of the marker. -1 means unknown marker.
  final int size;

  /// null means unknown marker.
  final String? description;

  /// Extra information about the marker.
  final Map<String, dynamic>? extra;

  JpegMarker(this.type, this.size, this.description, {this.extra});

  @override
  String toString() {
    final extraStr = extra?.entries.map((e) => '${e.key}: ${e.value}');
    final hexType = '0x${type.toRadixString(16).toUpperCase()}';
    String s = hexType;
    s += '(${description ?? 'Unknown'})';
    if (size >= 0) {
      s += ' | Size: $size';
    }
    if (extraStr != null) {
      s += ' | Extra: {${extraStr.join(', ')}}';
    }
    return s;
  }
}

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
    if (marker != null) {
      if (marker.size < 0) {
        // Assume the size is stored in the next two bytes.
        offset += _calculateMarkerSize(markerData);
      } else {
        // End of image.
        if (marker.size == 0) {
          break;
        }
        offset += marker.size;
      }
    } else {
      // Find the next 0xff byte.
      offset = data.indexOf(0xff, offset + 1);
    }
  }
}

int _calculateMarkerSize(Uint8List data) {
  return 2 + data[2] * 256 + data[3];
}

JpegMarker? _showMarkers(Uint8List data) {
  if (data[0] != 0xff) {
    return null;
  }

  switch (data[1]) {
    case 0xc0:
      return JpegMarker(
          data[1], _calculateMarkerSize(data), 'Start of Frame (baseline)');

    case 0xc1:
      return JpegMarker(data[1], _calculateMarkerSize(data),
          'Start of Frame (extended sequential)');

    case 0xc2:
      return JpegMarker(
          data[1], _calculateMarkerSize(data), 'Start of Frame (progressive)',
          extra: {
            'P': data[4],
            'Y': 256 * data[5] + data[6],
            'X': 256 * data[7] + data[8],
            'Nf': data[9],
          });

    case 0xc3:
      return JpegMarker(
          data[1], _calculateMarkerSize(data), 'Start of Frame (lossless)');

    case 0xc4:
      return JpegMarker(data[1], _calculateMarkerSize(data), 'Define Huffman');

    case 0xd0:
    case 0xd1:
    case 0xd2:
    case 0xd3:
    case 0xd4:
    case 0xd5:
    case 0xd6:
    case 0xd7:
      return JpegMarker(data[1], 2, 'Restart');

    case 0xd8:
      return JpegMarker(data[1], 2, 'SOI');

    case 0xd9:
      return JpegMarker(data[1], 0, 'End of Image');

    case 0xda:
      print("FFDA: Start of Scan [NC:${data[4]}]");
      int headersize = _calculateMarkerSize(data);
      int offset = headersize;
      while (true) {
        if (data[offset] == 0xff && data[offset + 1] != 0x00) break;
        offset++;
      }
      return JpegMarker(data[1], offset, 'Start of Scan', extra: {
        'NC': data[4],
        'size': offset - headersize,
      });

    case 0xdb:
      return JpegMarker(
          data[1], _calculateMarkerSize(data), 'Define Quantization');

    case 0xdd:
      return JpegMarker(
          data[1],
          // 2 bytes for marker, 4 bytes for data.
          2 + 4,
          'Define Restart Interval');

    case 0xe0:
      return JpegMarker(data[1], _calculateMarkerSize(data), 'JFIF', extra: {
        'V': 256 * data[8] + data[9],
        'U': '${data[10]}/${data[11]}',
        'Xd': 256 * data[12] + data[13],
        'Yd': 256 * data[14] + data[15],
        'Xt': data[16],
        'Yt': data[17],
      });

    case 0xe1:
      return JpegMarker(data[1], _calculateMarkerSize(data), 'EXIF');

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
      return JpegMarker(
          data[1], _calculateMarkerSize(data), 'APP${data[1] - 0xe0}');

    case 0xfe:
      return JpegMarker(data[1], _calculateMarkerSize(data), 'Comment');

    default:
      print(
          "Unknown: ${data[0].toRadixString(16).toUpperCase()} ${data[1].toRadixString(16).toUpperCase()}");
      return JpegMarker(data[1], -1, null);
  }
}
