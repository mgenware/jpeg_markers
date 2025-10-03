// ignore_for_file: avoid_print

import 'dart:io';

import 'package:jpeg_markers/jpeg_markers.dart';

Future<void> main(List<String> args) async {
  final file = File('test/files/base.jpg');
  final bytes = await file.readAsBytes();
  scanJpegMarkers(bytes, (marker, offset) {
    print('$offset: $marker');
  });
}
