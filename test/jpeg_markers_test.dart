import 'dart:io';

import 'package:jpeg_markers/jpeg_markers.dart';
import 'package:test/test.dart';

Future<void> _t(
  String fileName,
  int offset, {
  String? dumpName,
  bool? continueOnNonMarkers,
}) async {
  final testFile = 'test/files/$fileName.jpg';
  final dumpFile = 'test/files/${dumpName ?? fileName}.txt';
  final List<String> res = [];
  final actualOffset = await scanJpegMarkers(
    await File(testFile).readAsBytes(),
    (offset, marker) async {
      res.add('$offset: $marker');
    },
    continueOnNonMarkers: continueOnNonMarkers,
  );
  final actual = res.join('\n');

  // Use this to update the expected file.
  // await File(dumpFile).writeAsString(actual);

  final expected = await File(dumpFile).readAsString();
  expect(actual, expected.trim());
  expect(actualOffset, offset);
}

void main() {
  test('Base', () async {
    await _t('base', 294203);
  });
  test('Pixel 8', () async {
    await _t('pixel_8', 267463);
  });
  test('Adobe', () async {
    await _t('adobe_hdr', 1113857);
  });
  test('gainmap_iso21496_1', () async {
    await _t('gainmap_iso21496_1', 1996);
  });
  test('payload (continueOnNonMarkers)', () async {
    await _t('payload', 2248, continueOnNonMarkers: true);
  });
  test('payload (stop on non-markers)', () async {
    await _t('payload', 1996, dumpName: 'payload_stopOnMarker');
  });
}
