import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sweethome_flutter/core/image_mime.dart';

Uint8List _bytes(List<int> v) => Uint8List.fromList(v);

void main() {
  group('detectImageMimeType', () {
    test('returns null for empty / too-short input', () {
      expect(detectImageMimeType(_bytes([])), isNull);
      expect(detectImageMimeType(_bytes([0xFF])), isNull);
      expect(detectImageMimeType(_bytes([0xFF, 0xD8])), isNull);
      expect(detectImageMimeType(_bytes([0xFF, 0xD8, 0xFF])), isNull);
    });

    test('detects JPEG (FF D8 FF)', () {
      expect(
        detectImageMimeType(_bytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])),
        'image/jpeg',
      );
    });

    test('detects PNG (89 50 4E 47)', () {
      expect(
        detectImageMimeType(_bytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])),
        'image/png',
      );
    });

    test('detects GIF87a and GIF89a', () {
      expect(detectImageMimeType(_bytes([0x47, 0x49, 0x46, 0x38, 0x37])),
          'image/gif');
      expect(detectImageMimeType(_bytes([0x47, 0x49, 0x46, 0x38, 0x39])),
          'image/gif');
    });

    test('detects BMP (42 4D)', () {
      expect(detectImageMimeType(_bytes([0x42, 0x4D, 0x00, 0x00])),
          'image/bmp');
    });

    test('detects WebP (RIFF....WEBP)', () {
      // RIFF header is 12 bytes; brand is at offset 8.
      expect(
        detectImageMimeType(_bytes([
          0x52, 0x49, 0x46, 0x46, // "RIFF"
          0x00, 0x00, 0x00, 0x00, // size (ignored)
          0x57, 0x45, 0x42, 0x50, // "WEBP"
          0x56, 0x50, 0x38, 0x4C, // "VP8L" payload
        ])),
        'image/webp',
      );
    });

    test('rejects RIFF files that are not WebP (e.g. WAV)', () {
      // "WAVE" at offset 8 is the WAV signature, same RIFF container.
      expect(
        detectImageMimeType(_bytes([
          0x52, 0x49, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00,
          0x57, 0x41, 0x56, 0x45, // "WAVE"
        ])),
        isNull,
      );
    });

    test('detects HEIC by ftyp+brand at offset 4/8', () {
      // heic: brand bytes [0x68,0x65,0x69,0x63]
      expect(
        detectImageMimeType(_bytes([
          0x00, 0x00, 0x00, 0x20, // box size
          0x66, 0x74, 0x79, 0x70, // "ftyp"
          0x68, 0x65, 0x69, 0x63, // "heic"
          0x00, 0x00, 0x00, 0x00,
        ])),
        'image/heic',
      );
    });

    test('detects AVIF by ftyp+avif brand', () {
      expect(
        detectImageMimeType(_bytes([
          0x00, 0x00, 0x00, 0x20,
          0x66, 0x74, 0x79, 0x70,
          0x61, 0x76, 0x69, 0x66, // "avif"
          0x00, 0x00, 0x00, 0x00,
        ])),
        'image/avif',
      );
    });

    test('treats unknown ISO base media brand as image/heic (best guess)',
        () {
      // Some Android camera apps write ftyp with a brand we don't
      // recognise — still an image, just conservatively labelled heic.
      expect(
        detectImageMimeType(_bytes([
          0x00, 0x00, 0x00, 0x20,
          0x66, 0x74, 0x79, 0x70,
          0x71, 0x71, 0x71, 0x71, // unknown
          0x00, 0x00, 0x00, 0x00,
        ])),
        'image/heic',
      );
    });

    test('returns null for random non-image bytes', () {
      expect(detectImageMimeType(_bytes([0x00, 0x01, 0x02, 0x03])), isNull);
      expect(
        detectImageMimeType(_bytes([0x50, 0x4B, 0x03, 0x04])), // ZIP/JAR/Office
        isNull,
      );
      expect(
        detectImageMimeType(_bytes([0x25, 0x50, 0x44, 0x46])), // PDF
        isNull,
      );
    });
  });
}