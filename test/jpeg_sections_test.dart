import 'dart:io';

import 'package:jpeg_markers/jpeg_markers.dart';
import 'package:test/test.dart';

Future<void> _t(String fileName) async {
  final testFile = 'test/files/$fileName.jpg';
  final dumpFile = 'test/files/${fileName}_sec.txt';
  final sections = scanJpegSections(
    await File(testFile).readAsBytes(),
  );

  final actual = sections.map((e) => e.toString()).join('\n');

  // Use this to update the expected file.
  // await File(dumpFile).writeAsString(actual);

  final expected = await File(dumpFile).readAsString();
  expect(actual, expected.trim());
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
  test('gainmap_iso21496_1', () async {
    await _t('gainmap_iso21496_1');
  });
  test('payload', () async {
    await _t('payload');
  });
  test('markers_img_gap_img', () async {
    await _t('markers_img_gap_img');
  });
  test('markers_img_gap_random_soi', () async {
    await _t('markers_img_gap_random_soi');
  });
}
