import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageUtils {
  /// Compress gambar dengan quality & max dimensi
  /// Return File hasil compress, atau file asli kalau gagal
  static Future<File> compressImage(File file, {
    int quality = 70,       // 0–100
    int maxWidth = 1280,    // max lebar pixel
    int maxHeight = 1280,   // max tinggi pixel
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final ext = path.extension(file.path).toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final targetPath = '${dir.path}/$fileName';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      return file; // fallback ke file asli
    }
  }
}