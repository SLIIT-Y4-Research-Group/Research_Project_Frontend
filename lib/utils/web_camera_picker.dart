// lib/utils/web_camera_picker.dart
import 'dart:async';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Uint8List?> pickImageFromWebCamera() async {
  final completer = Completer<Uint8List?>();

  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..setAttribute('capture', 'camera');

  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.readAsArrayBuffer(files.first);

    reader.onLoadEnd.listen((event) {
      final result = reader.result;
      if (result is Uint8List) {
        completer.complete(result);
      } else if (result is ByteBuffer) {
        completer.complete(result.asUint8List());
      } else {
        completer.complete(null);
      }
    });
  });

  return completer.future;
}
