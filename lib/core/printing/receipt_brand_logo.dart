import 'package:flutter/services.dart';
import 'package:image_v3/image_v3.dart' as img;

/// SPiD / Valet Master mark for thermal receipts (raster + ESC/POS image).
abstract final class ReceiptBrandLogo {
  static const assetPath = 'assets/images/spid_logo1.png';

  static img.Image? _cache;
  static int _cacheMaxWidth = 0;

  static Future<img.Image?> loadForReceipt({int maxWidthPx = 168}) async {
    if (_cache != null && _cacheMaxWidth == maxWidthPx) return _cache;
    try {
      final data = await rootBundle.load(assetPath);
      final decoded = img.decodeImage(data.buffer.asUint8List());
      if (decoded == null) return null;
      final w = decoded.width > maxWidthPx ? maxWidthPx : decoded.width;
      _cache = img.copyResize(decoded, width: w);
      _cacheMaxWidth = maxWidthPx;
      return _cache;
    } catch (_) {
      return null;
    }
  }
}
