import 'dart:io';

import 'package:jpeg_markers/jpeg_markers.dart';
import 'package:test/test.dart';

Future<void> _t(String fileName) async {
  final image = 'test/files/$fileName.jpg';
  final dump = 'test/files/$fileName.txt';
  final List<String> res = [];
  scanJpegMarkers(await File(image).readAsBytes(), (offset, marker) {
    res.add('$offset: $marker');
    return true;
  });
  final actual = res.join('\n');
  final expected = await File(dump).readAsString();
  expect(actual, expected);
}

void main() {
  test('Base', () async {
    await _t('base');
  });
}
