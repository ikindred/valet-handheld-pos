import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_v3/image_v3.dart' as img;

abstract final class ReceiptBrandLogo {
  static const assetPath = 'assets/images/spid_logo.png';
  static img.Image? _cache;
  static int _cacheMaxWidth = 0;

  static Future<img.Image?> loadForReceipt({int maxWidthPx = 160}) async {
    if (_cache != null && _cacheMaxWidth == maxWidthPx) return _cache;
    try {
      final data = await rootBundle.load(assetPath);
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded == null) {
        debugPrint(
          'ReceiptBrandLogo: decodeImage returned null for $assetPath',
        );
        return null;
      }
      final w = decoded.width > maxWidthPx ? maxWidthPx : decoded.width;
      var prepared = img.copyResize(decoded, width: w);
      prepared = _flattenOnWhite(prepared);
      prepared = _padWidthToMultipleOf8(prepared);
      _cache = prepared;
      _cacheMaxWidth = maxWidthPx;
      return _cache;
    } catch (e, st) {
      debugPrint('ReceiptBrandLogo: failed to load $assetPath: $e\n$st');
      return null;
    }
  }

  static img.Image _flattenOnWhite(img.Image source) {
    final flat = img.Image(source.width, source.height);
    img.fill(flat, 0xffffffff);
    img.drawImage(flat, source, blend: false);
    // Force all pixels: white where transparent, keep color where opaque
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final srcPixel = source.getPixel(x, y);
        final a = img.getAlpha(srcPixel);
        if (a < 128) {
          flat.setPixel(x, y, 0xffffffff); // transparent → white
        } else {
          flat.setPixel(
            x,
            y,
            srcPixel | 0xff000000,
          ); // opaque → keep, force alpha
        }
      }
    }
    return flat;
  }

  static img.Image _padWidthToMultipleOf8(img.Image source) {
    final paddedWidth = (source.width + 7) & ~7;
    if (paddedWidth <= source.width) return source;
    final out = img.Image(paddedWidth, source.height);
    img.fill(out, 0xffffffff);
    img.drawImage(out, source, blend: false);
    return out;
  }
}
