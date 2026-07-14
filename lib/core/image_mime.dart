import 'dart:typed_data';

/// Detects the image MIME type from the first few bytes of the file
/// (the standard "magic bytes"). Returns `null` for unrecognized
/// formats.
///
/// `image_picker`'s `XFile.mimeType` is unreliable on Android — for
/// some files (HEIC straight from a camera, some WebPs, anything from a
/// non-system picker) it returns `null`, which the backend's
/// `UploadServiceImpl` then rejects as `FILE_TYPE_ILLEGAL` (the part's
/// Content-Type falls back to `application/octet-stream`). Sniffing the
/// actual bytes is the only way to guarantee a real `image/*` MIME on
/// every platform.
///
/// The list below covers every format the device's default
/// `ACTION_PICK` / `ACTION_GET_CONTENT` / `PhotoPicker` intents can
/// surface. Add new formats by appending their leading-byte signature
/// here.
String? detectImageMimeType(Uint8List bytes) {
  if (bytes.length < 4) return null;

  // JPEG: FF D8 FF
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  // PNG: 89 50 4E 47
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
    return 'image/png';
  }
  // GIF: 47 49 46 38 (or 39 for GIF89a)
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 &&
      (bytes[3] == 0x38 || bytes[3] == 0x39)) {
    return 'image/gif';
  }
  // BMP: 42 4D
  if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return 'image/bmp';
  }
  // WebP: "RIFF" .... "WEBP" — note the brand is at offset 8, not 0
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
      bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
    return 'image/webp';
  }
  // ISO base media (HEIC / HEIF / AVIF) — has 'ftyp' at offset 4, brand
  // at offset 8. Modern Android cameras save HEIC here.
  if (bytes.length >= 12 &&
      bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) {
    final brand = String.fromCharCodes(bytes.sublist(8, 12));
    switch (brand) {
      case 'heic':
      case 'heix':
      case 'heim':
      case 'heis':
      case 'mif1':
      case 'msf1':
        return 'image/heic';
      case 'avif':
      case 'avis':
        return 'image/avif';
      default:
        // Unknown ISO brand — still image/*, fall back to heic.
        return 'image/heic';
    }
  }
  return null;
}