# jpeg_markers

[![pub package](https://img.shields.io/pub/v/jpeg_markers.svg)](https://pub.dev/packages/jpeg_markers)
[![Build Status](https://github.com/mgenware/jpeg_markers/workflows/Dart/badge.svg)](https://github.com/mgenware/jpeg_markers/actions)

Scan JPEG markers in a JPEG file.

## Usage

```dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:jpeg_markers/jpeg_markers.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    return;
  }

  final file = File(args[0]);
  final bytes = await file.readAsBytes();
  scanJpegMarkers(bytes, (marker, offset) {
    print('$offset: $marker');
    return true;
  });
}
```

Example output:

```
0xD8(SOI) | Size: 2: 0
0xE0(JFIF) | Size: 18 | Extra: {V: 1, U: 1/1, Xd: 72, Yd: 72, Xt: 0, Yt: 0}: 2
0xED(APP13) | Size: 8744: 20
0xE1(APP1) | Size: 38: 8764
0xE2(APP2) | Size: 3162: 8802
0xE1(APP1) | Size: 5587: 11964
0xDB(DQT) | Size: 69: 17551
0xDB(DQT) | Size: 69: 17620
0xC2(SOF (progressive)) | Size: 19 | Extra: {P: 8, Y: 522, X: 783, Nf: 3}: 17689
0xC4(DHT) | Size: 31: 17708
0xC4(DHT) | Size: 26: 17739
0xDA(SOS) | Size: 8198 | Extra: {NC: 3, size: 8184}: 17765
0xC4(DHT) | Size: 52: 25963
0xDA(SOS) | Size: 21284 | Extra: {NC: 1, size: 21274}: 26015
0xC4(DHT) | Size: 53: 47299
0xDA(SOS) | Size: 1343 | Extra: {NC: 1, size: 1333}: 47352
0xC4(DHT) | Size: 52: 48695
0xDA(SOS) | Size: 1292 | Extra: {NC: 1, size: 1282}: 48747
0xC4(DHT) | Size: 85: 50039
0xDA(SOS) | Size: 147501 | Extra: {NC: 1, size: 147491}: 50124
0xC4(DHT) | Size: 41: 197625
0xDA(SOS) | Size: 44424 | Extra: {NC: 1, size: 44414}: 197666
0xDA(SOS) | Size: 2440 | Extra: {NC: 3, size: 2426}: 242090
0xC4(DHT) | Size: 37: 244530
0xDA(SOS) | Size: 585 | Extra: {NC: 1, size: 575}: 244567
0xC4(DHT) | Size: 37: 245152
0xDA(SOS) | Size: 587 | Extra: {NC: 1, size: 577}: 245189
0xC4(DHT) | Size: 41: 245776
0xDA(SOS) | Size: 48384 | Extra: {NC: 1, size: 48374}: 245817
0xD9(EOI) | Size: 0: 294201
```
