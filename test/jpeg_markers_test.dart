import 'dart:io';

import 'package:jpeg_markers/jpeg_markers.dart';
import 'package:test/test.dart';

Future<void> _t(String fileName) async {
  final testFile = 'test/files/$fileName.jpg';
  final dumpFile = 'test/files/$fileName.txt';
  final List<String> res = [];
  scanJpegMarkers(await File(testFile).readAsBytes(), (offset, marker) {
    res.add('$offset: $marker');
    return true;
  });
  final actual = res.join('\n');

  // Use this to update the expected file.
  // await File(dumpFile).writeAsString(actual);

  final expected = await File(dumpFile).readAsString();
  expect(actual, expected);
}

void main() {
  test('Base', () async {
    await _t('base');
  });
  test('Pixel 8', () async {
    await _t('pixel_8');
  });
  test('Adobe', () async {
    await _t('adobe_hdr');
  });
}
