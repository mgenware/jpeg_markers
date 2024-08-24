// ignore_for_file: avoid_print

import 'dart:io';
import 'package:jpeg_markers/jpeg_markers.dart';

Future<void> main(List<String> args) async {
  final file = File('test/files/pixel_8.jpg');
  final bytes = await file.readAsBytes();
  scanJpegMarkers(bytes, (marker, offset) {
    if (marker.type == 0xE1) {
      print('  >>> e1 ');
    }
    print('$offset: $marker');
    return true;
  });
}
