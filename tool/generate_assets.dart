import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  Directory('assets/icons').createSync(recursive: true);
  Directory('assets/images').createSync(recursive: true);

  print('Generating app icon...');
  final iconPng = generateAppIcon(512, 512);
  File('assets/icons/app_icon.png').writeAsBytesSync(iconPng);

  print('Generating department avatars & badges...');
  File('assets/images/avatar_mobile.png').writeAsBytesSync(generateDepartmentAvatar(256, 256, 0x1E, 0x88, 0xE5, 'MOBILE'));
  File('assets/images/avatar_field.png').writeAsBytesSync(generateDepartmentAvatar(256, 256, 0x43, 0xA0, 0x47, 'FIELD'));
  File('assets/images/avatar_cloud.png').writeAsBytesSync(generateDepartmentAvatar(256, 256, 0x8E, 0x24, 0xAA, 'CLOUD'));
  File('assets/images/avatar_security.png').writeAsBytesSync(generateDepartmentAvatar(256, 256, 0x00, 0xAC, 0xC1, 'SEC'));
  File('assets/images/call_badge.png').writeAsBytesSync(generateVoipBadge(256, 256));
  File('assets/images/geofence_marker.png').writeAsBytesSync(generateGeofenceMarker(256, 256));

  print('All assets generated successfully.');
}

Uint8List generateAppIcon(int width, int height) {
  final buffer = Uint8List(width * height * 4);
  final cx = width / 2;
  final cy = height / 2;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);

      // Deep Obsidian background with subtle radial gradient
      double bgR = 15.0 + (10.0 * (1.0 - min(1.0, dist / (width * 0.7))));
      double bgG = 23.0 + (15.0 * (1.0 - min(1.0, dist / (width * 0.7))));
      double bgB = 42.0 + (25.0 * (1.0 - min(1.0, dist / (width * 0.7))));
      double alpha = 255.0;

      // Hexagonal Shield Outline
      final angle = atan2(dy, dx);
      final hexR = (width * 0.38) / (cos((angle % (pi / 3)) - (pi / 6)));
      final shieldDist = (dist - hexR).abs();

      if (shieldDist < 8.0) {
        // Cobalt to Emerald border
        final t = (angle + pi) / (2 * pi);
        bgR = 14.0 * (1 - t) + 16.0 * t;
        bgG = 165.0 * (1 - t) + 185.0 * t;
        bgB = 233.0 * (1 - t) + 129.0 * t;
      } else if (dist < hexR) {
        // Inside Shield: Dark slate-blue
        bgR = 18.0;
        bgG = 30.0;
        bgB = 58.0;

        // Acoustic VoIP Waveform across center
        final waveY = cy + 24.0 * sin(dx * 0.05) * exp(-pow(dx / (width * 0.32), 2));
        if ((y - waveY).abs() < 5.0 && dx.abs() < width * 0.32) {
          bgR = 56.0;
          bgG = 189.0;
          bgB = 248.0; // Electric sky blue
        }

        // Orbital Node / Geofence Circle
        final nodeDist = sqrt(dx * dx + (dy + 35) * (dy + 35));
        if ((nodeDist - 28.0).abs() < 4.0) {
          bgR = 16.0;
          bgG = 185.0;
          bgB = 129.0; // Emerald
        } else if (nodeDist < 12.0) {
          bgR = 240.0;
          bgG = 253.0;
          bgB = 250.0;
        }
      }

      buffer[idx] = bgR.clamp(0, 255).toInt();
      buffer[idx + 1] = bgG.clamp(0, 255).toInt();
      buffer[idx + 2] = bgB.clamp(0, 255).toInt();
      buffer[idx + 3] = alpha.toInt();
    }
  }

  return encodePng(width, height, buffer);
}

Uint8List generateDepartmentAvatar(int width, int height, int r, int g, int b, String tag) {
  final buffer = Uint8List(width * height * 4);
  final cx = width / 2;
  final cy = height / 2;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= width * 0.44) {
        // Gradient circle
        final grad = (1.0 - (dist / (width * 0.44))).clamp(0.0, 1.0);
        buffer[idx] = (r * 0.6 + r * 0.4 * grad).clamp(0, 255).toInt();
        buffer[idx + 1] = (g * 0.6 + g * 0.4 * grad).clamp(0, 255).toInt();
        buffer[idx + 2] = (b * 0.6 + b * 0.4 * grad).clamp(0, 255).toInt();
        buffer[idx + 3] = 255;

        // Inner ring
        if ((dist - width * 0.38).abs() < 3.0) {
          buffer[idx] = 255;
          buffer[idx + 1] = 255;
          buffer[idx + 2] = 255;
        }
      } else {
        buffer[idx] = 0;
        buffer[idx + 1] = 0;
        buffer[idx + 2] = 0;
        buffer[idx + 3] = 0;
      }
    }
  }
  return encodePng(width, height, buffer);
}

Uint8List generateVoipBadge(int width, int height) {
  final buffer = Uint8List(width * height * 4);
  final cx = width / 2;
  final cy = height / 2;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= width * 0.42) {
        buffer[idx] = 16;
        buffer[idx + 1] = 185;
        buffer[idx + 2] = 129;
        buffer[idx + 3] = 255;

        if ((dist - width * 0.36).abs() < 3.0) {
          buffer[idx] = 255;
          buffer[idx + 1] = 255;
          buffer[idx + 2] = 255;
        }
      } else {
        buffer[idx] = 0;
        buffer[idx + 1] = 0;
        buffer[idx + 2] = 0;
        buffer[idx + 3] = 0;
      }
    }
  }
  return encodePng(width, height, buffer);
}

Uint8List generateGeofenceMarker(int width, int height) {
  final buffer = Uint8List(width * height * 4);
  final cx = width / 2;
  final cy = height / 2;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final idx = (y * width + x) * 4;
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= width * 0.42) {
        buffer[idx] = 14;
        buffer[idx + 1] = 165;
        buffer[idx + 2] = 233;
        buffer[idx + 3] = 255;

        if (dist <= width * 0.2) {
          buffer[idx] = 255;
          buffer[idx + 1] = 255;
          buffer[idx + 2] = 255;
        }
      } else {
        buffer[idx] = 0;
        buffer[idx + 1] = 0;
        buffer[idx + 2] = 0;
        buffer[idx + 3] = 0;
      }
    }
  }
  return encodePng(width, height, buffer);
}

Uint8List encodePng(int width, int height, Uint8List rgbaBytes) {
  // Construct raw scanlines with filter byte 0 (None)
  final rawScanlines = Uint8List(height * (1 + width * 4));
  int srcIdx = 0;
  int dstIdx = 0;
  for (int y = 0; y < height; y++) {
    rawScanlines[dstIdx++] = 0; // Filter None
    for (int x = 0; x < width * 4; x++) {
      rawScanlines[dstIdx++] = rgbaBytes[srcIdx++];
    }
  }

  final compressed = Uint8List.fromList(zlib.encode(rawScanlines));

  final out = BytesBuilder();
  // PNG Signature
  out.add([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR chunk
  final ihdrData = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // Bit depth: 8
    ..setUint8(9, 6) // Color type: RGBA (6)
    ..setUint8(10, 0) // Compression: Deflate
    ..setUint8(11, 0) // Filter: standard
    ..setUint8(12, 0); // Interlace: none
  writeChunk(out, 'IHDR', ihdrData.buffer.asUint8List());

  // IDAT chunk
  writeChunk(out, 'IDAT', compressed);

  // IEND chunk
  writeChunk(out, 'IEND', Uint8List(0));

  return out.toBytes();
}

void writeChunk(BytesBuilder out, String type, Uint8List data) {
  final length = data.length;
  final lengthBytes = ByteData(4)..setUint32(0, length);
  out.add(lengthBytes.buffer.asUint8List());

  final typeBytes = Uint8List.fromList(type.codeUnits);
  out.add(typeBytes);
  out.add(data);

  final crcData = Uint8List(4 + length);
  crcData.setRange(0, 4, typeBytes);
  crcData.setRange(4, 4 + length, data);
  final crcVal = crc32(crcData);

  final crcBytes = ByteData(4)..setUint32(0, crcVal);
  out.add(crcBytes.buffer.asUint8List());
}

int crc32(Uint8List data) {
  int crc = 0xffffffff;
  for (int byte in data) {
    crc ^= byte;
    for (int k = 0; k < 8; k++) {
      crc = (crc & 1 != 0) ? (0xedb88320 ^ (crc >>> 1)) : (crc >>> 1);
    }
  }
  return crc ^ 0xffffffff;
}
