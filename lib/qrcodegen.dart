import 'dart:convert';
import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

// Ported from https://github.com/nayuki/QR-Code-generator/blob/master/typescript-javascript/qrcodegen.ts
// Thanks @nayuki <3
/*
 * QR Code generator library (TypeScript)
 *
 * Copyright (c) Project Nayuki. (MIT License)
 * https://www.nayuki.io/page/qr-code-generator-library
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 * - The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * - The Software is provided "as is", without warranty of any kind, express or
 *   implied, including but not limited to the warranties of merchantability,
 *   fitness for a particular purpose and noninfringement. In no event shall the
 *   authors or copyright holders be liable for any claim, damages or other
 *   liability, whether in an action of contract, tort or otherwise, arising from,
 *   out of or in connection with the Software or the use or other dealings in the
 *   Software.
 */


// Appends the given number of low-order bits of the given value
// to the given buffer. Requires 0 <= len <= 31 and 0 <= val < 2^len.
void appendBits(int val, int len, List bb) {
  if (len < 0 || len > 31 || val >> len != 0)
    throw "Value out of range";
  for (var i = len - 1; i >= 0; i--)  // Append bit by bit
    bb.add((val >> i) & 1);
}

// Returns true iff the i'th bit of x is set to 1.
bool getBit(int x, int i) {
  return ((x >> i) & 1) != 0;
}

// https://pub.dev/documentation/js_shims/latest/js_shims/splice.html
List<T> splice<T>(List<T> list, int index, [num howMany = 0, /*<T | List<T>>*/ elements]) {
  var endIndex = index + howMany.truncate();
  list.removeRange(index, endIndex >= list.length ? list.length : endIndex);
  if (elements != null) list.insertAll(index, elements is List<T> ? elements : <T>[elements]);
  return list;
}

/*
 * A QR Code symbol, which is a type of two-dimension barcode.
 * Invented by Denso Wave and described in the ISO/IEC 18004 standard.
 * Instances of this class represent an immutable square grid of black and white cells.
 * The class provides static factory functions to create a QR Code from text or binary data.
 * The class covers the QR Code Model 2 specification, supporting all versions (sizes)
 * from 1 to 40, all 4 error correction levels, and 4 character encoding modes.
 *
 * Ways to create a QR Code object:
 * - High level: Take the payload data and call QrCode.encodeText() or QrCode.encodeBinary().
 * - Mid level: Custom-make the list of segments and call QrCode.encodeSegments().
 * - Low level: Custom-make the array of data codeword bytes (including
 *   segment headers and final padding, excluding error correction codewords),
 *   supply the appropriate version number, and call the QrCode() constructor.
 * (Note that all ways require supplying the desired error correction level.)
 */
class QrCode {
  /*-- Constants and tables --*/

  // The minimum version number supported in the QR Code Model 2 standard.
  static const int MIN_VERSION = 1;
  // The maximum version number supported in the QR Code Model 2 standard.
  static const int MAX_VERSION = 40;

  // For use in getPenaltyScore(), when evaluating which mask is best.
  static const int PENALTY_N1 =  3;
  static const int PENALTY_N2 =  3;
  static const int PENALTY_N3 = 40;
  static const int PENALTY_N4 = 10;

  static const List<List<int>> ECC_CODEWORDS_PER_BLOCK = [
  // Version: (note that index 0 is for padding, and is set to an illegal value)
  //0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40    Error correction level
  [-1,  7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],  // Low
  [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],  // Medium
  [-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],  // Quartile
  [-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],  // High
  ];

  static const List<List<int>> NUM_ERROR_CORRECTION_BLOCKS = [
  // Version: (note that index 0 is for padding, and is set to an illegal value)
  //0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40    Error correction level
  [-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4,  4,  4,  4,  4,  6,  6,  6,  6,  7,  8,  8,  9,  9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],  // Low
  [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5,  5,  8,  9,  9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],  // Medium
  [-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8,  8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],  // Quartile
  [-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81],  // High
  ];

  /*-- Static factory functions (high level) --*/

  // Returns a QR Code representing the given Unicode text string at the given error correction level.
  // As a conservative upper bound, this function is guaranteed to succeed for strings that have 738 or fewer
  // Unicode code points (not UTF-16 code units) if the low error correction level is used. The smallest possible
  // QR Code version is automatically chosen for the output. The ECC level of the result may be higher than the
  // ecl argument if it can be done without increasing the version.
  static QrCode encodeText(String text, QrCodeEcc ecl, {
    int minVersion = 1,
    int maxVersion = 40,
    int mask = -1,
    bool boostEcl = true
  }) {
    List<QrSegment> segs = QrSegment.makeSegments(text);
    return QrCode.encodeSegments(segs, ecl,
      minVersion: minVersion,
      maxVersion: maxVersion,
      mask: mask,
      boostEcl: boostEcl);
  }

  // Returns a QR Code representing the given binary data at the given error correction level.
  // This function always encodes using the binary segment mode, not any text mode. The maximum number of
  // bytes allowed is 2953. The smallest possible QR Code version is automatically chosen for the output.
  // The ECC level of the result may be higher than the ecl argument if it can be done without increasing the version.
  static QrCode encodeBinary(Uint8List data, QrCodeEcc ecl) {
    QrSegment seg = QrSegment.makeBytes(data);
    return QrCode.encodeSegments([seg], ecl);
  }

  /*-- Static factory functions (mid level) --*/

  // Returns a QR Code representing the given segments with the given encoding parameters.
  // The smallest possible QR Code version within the given range is automatically
  // chosen for the output. Iff boostEcl is true, then the ECC level of the result
  // may be higher than the ecl argument if it can be done without increasing the
  // version. The mask number is either between 0 to 7 (inclusive) to force that
  // mask, or -1 to automatically choose an appropriate mask (which may be slow).
  // This function allows the user to create a custom sequence of segments that switches
  // between modes (such as alphanumeric and byte) to encode text in less space.
  // This is a mid-level API; the high-level API is encodeText() and encodeBinary().
  static QrCode encodeSegments(List<QrSegment> segs, QrCodeEcc ecl, {
    int minVersion = 1,
    int maxVersion = 40,
    int mask = -1,
    bool boostEcl = true
  }) {
    if (!(QrCode.MIN_VERSION <= minVersion && minVersion <= maxVersion && maxVersion <= QrCode.MAX_VERSION)
      || mask < -1 || mask > 7) {
      throw "Invalid value";
    }

    // Find the minimal version number to use
    int version;
    int dataUsedBits;
    for (version = minVersion; ; version++) {
      int dataCapacityBits = QrCode.getNumDataCodewords(version, ecl) * 8;
      int usedBits = QrSegment.getTotalBits(segs, version);
      if (usedBits <= dataCapacityBits) {
        dataUsedBits = usedBits;
        break;  // This version number is found to be suitable
      }
      if (version >= maxVersion)  // All versions in the range could not fit the given data
        throw "Data too long";
    }

    // Increase the error correction level while the data still fits in the current version number
    for (var newEcl in [QrCodeEcc.MEDIUM, QrCodeEcc.QUARTILE, QrCodeEcc.HIGH]) {  // From low to high
      if (boostEcl && dataUsedBits <= QrCode.getNumDataCodewords(version, newEcl) * 8)
        ecl = newEcl;
    }

    // Concatenate all segments to create the data bit string
    List<int> bb = [];
    for (final seg in segs) {
      appendBits(seg.mode.modeBits, 4, bb);
      appendBits(seg.numChars, seg.mode.numCharCountBits(version), bb);
      for (final b in seg.getData())
        bb.add(b);
    }
    if (bb.length != dataUsedBits)
      throw "Assertion error";

    // Add terminator and pad up to a byte if applicable
    int dataCapacityBits = QrCode.getNumDataCodewords(version, ecl) * 8;
    if (bb.length > dataCapacityBits)
      throw "Assertion error";
    appendBits(0, min(4, dataCapacityBits - bb.length), bb);
    appendBits(0, (8 - bb.length % 8) % 8, bb);
    if (bb.length % 8 != 0)
      throw "Assertion error";

    // Pad with alternating bytes until data capacity is reached
    for (var padByte = 0xEC; bb.length < dataCapacityBits; padByte ^= 0xEC ^ 0x11)
      appendBits(padByte, 8, bb);

    // Pack bits into bytes in big endian
    List<int> dataCodewords = [];
    while (dataCodewords.length * 8 < bb.length)
      dataCodewords.add(0);
    bb.asMap().forEach((int i, int b) {
      dataCodewords[i >> 3] |= b << (7 - (i & 7));
    });

    // Create the QR Code object
    return QrCode(version, ecl, dataCodewords, mask);
  }

  /*-- Fields --*/

  // The width and height of this QR Code, measured in modules, between
  // 21 and 177 (inclusive). This is equal to version * 4 + 17.
  int size;

  // The modules of this QR Code (false = white, true = black).
  // Immutable after constructor finishes. Accessed through getModule().
  List<List<bool>> modules = [];

  // Indicates function modules that are not subjected to masking. Discarded when constructor finishes.
  List<List<bool>> isFunction = [];

  // The version number of this QR Code, which is between 1 and 40 (inclusive).
  // This determines the size of this barcode.
  int version;

  // The error correction level used in this QR Code.
  QrCodeEcc errorCorrectionLevel;

  // The index of the mask pattern used in this QR Code, which is between 0 and 7 (inclusive).
  // Even if a QR Code is created with automatic masking requested (mask = -1),
  // the resulting object still has a mask value between 0 and 7.
  int mask;


  /*-- Constructor (low level) and fields --*/

  // Creates a new QR Code with the given version number,
  // error correction level, data codeword bytes, and mask number.
  // This is a low-level API that most users should not use directly.
  // A mid-level API is the encodeSegments() function.
  QrCode(this.version, this.errorCorrectionLevel, List<int> dataCodewords, this.mask) {
    // Check scalar arguments
    if (version < QrCode.MIN_VERSION || version > QrCode.MAX_VERSION)
      throw "Version value out of range";
    if (mask < -1 || mask > 7)
      throw "Mask value out of range";
    this.size = version * 4 + 17;


    // Initialize both grids to be size*size arrays of Boolean false
    List<bool> row = [];
    for (var i = 0; i < this.size; i++)
      row.add(false);
    for (var i = 0; i < this.size; i++) {
      this.modules   .add(List.from(row));  // Initially all white
      this.isFunction.add(List.from(row));
    }

    // Compute ECC, draw modules
    this.drawFunctionPatterns();
    List<int> allCodewords = this.addEccAndInterleave(dataCodewords);
    this.drawCodewords(allCodewords);

    // Do masking
    if (mask == -1) {  // Automatically choose best mask
      int minPenalty = 1000000000;
      for (var i = 0; i < 8; i++) {
        this.applyMask(i);
        this.drawFormatBits(i);
        int penalty = this.getPenaltyScore();
        if (penalty < minPenalty) {
          mask = i;
          minPenalty = penalty;
        }
        this.applyMask(i);  // Undoes the mask due to XOR
      }
    }
    if (mask < 0 || mask > 7)
    throw "Assertion error";
    this.mask = mask;
    this.applyMask(mask);  // Apply the final choice of mask
    this.drawFormatBits(mask);  // Overwrite old format bits

    this.isFunction = [];
  }

  /*-- Accessor methods --*/

  // Returns the color of the module (pixel) at the given coordinates, which is false
  // for white or true for black. The top left corner has the coordinates (x=0, y=0).
  // If the given coordinates are out of bounds, then false (white) is returned.
  bool getModule(int x, int y) {
    return 0 <= x && x < this.size && 0 <= y && y < this.size && this.modules[y][x];
  }


  /*-- Public instance methods --*/
  // Returns a string of SVG code for an image depicting this QR Code, with the given number
  // of border modules. The string always uses Unix newlines (\n), regardless of the platform.
  String toSvgString(int border) {
  if (border < 0)
    throw "Border must be non-negative";
  List<String> parts = [];
  for (var y = 0; y < this.size; y++) {
    for (var x = 0; x < this.size; x++) {
      if (this.getModule(x, y))
        parts.add('M${x + border},${y + border}h1v1h-1z');
    }
  }
  return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg xmlns="http://www.w3.org/2000/svg" version="1.1" viewBox="0 0 ${this.size + border * 2} ${this.size + border * 2}" stroke="none">
<rect width="100" height="100" fill="#FFFFFF"/>
<path d="${parts.join(' ')}" fill="#000000"/>
</svg>
''';
  }


  /*-- Private helper methods for constructor: Drawing function modules --*/

  // Reads this object's version field, and draws and marks all function modules.
  void drawFunctionPatterns() {
    // Draw horizontal and vertical timing patterns
    for (var i = 0; i < this.size; i++) {
      this.setFunctionModule(6, i, i % 2 == 0);
      this.setFunctionModule(i, 6, i % 2 == 0);
    }

    // Draw 3 finder patterns (all corners except bottom right; overwrites some timing modules)
    this.drawFinderPattern(3, 3);
    this.drawFinderPattern(this.size - 4, 3);
    this.drawFinderPattern(3, this.size - 4);

    // Draw numerous alignment patterns
    List<int> alignPatPos = this.getAlignmentPatternPositions();
    int numAlign = alignPatPos.length;
    for (var i = 0; i < numAlign; i++) {
      for (var j = 0; j < numAlign; j++) {
        // Don't draw on the three finder corners
        if (!(i == 0 && j == 0 || i == 0 && j == numAlign - 1 || i == numAlign - 1 && j == 0))
          this.drawAlignmentPattern(alignPatPos[i], alignPatPos[j]);
      }
    }

    // Draw configuration data
    this.drawFormatBits(0);  // Dummy mask value; overwritten later in the constructor
    this.drawVersion();
  }


  // Draws two copies of the format bits (with its own error correction code)
  // based on the given mask and this object's error correction level field.
  void drawFormatBits(int mask) {
    // Calculate error correction code and pack bits
    int data = this.errorCorrectionLevel.formatBits << 3 | mask;  // errCorrLvl is uint2, mask is uint3
    int rem = data;
    for (var i = 0; i < 10; i++)
    rem = (rem << 1) ^ ((rem >> 9) * 0x537);
    int bits = (data << 10 | rem) ^ 0x5412;  // uint15
    if (bits >> 15 != 0)
      throw "Assertion error";

    // Draw first copy
    for (var i = 0; i <= 5; i++)
      this.setFunctionModule(8, i, getBit(bits, i));
    this.setFunctionModule(8, 7, getBit(bits, 6));
    this.setFunctionModule(8, 8, getBit(bits, 7));
    this.setFunctionModule(7, 8, getBit(bits, 8));
    for (var i = 9; i < 15; i++)
      this.setFunctionModule(14 - i, 8, getBit(bits, i));

    // Draw second copy
    for (var i = 0; i < 8; i++)
    this.setFunctionModule(this.size - 1 - i, 8, getBit(bits, i));
    for (var i = 8; i < 15; i++)
    this.setFunctionModule(8, this.size - 15 + i, getBit(bits, i));
    this.setFunctionModule(8, this.size - 8, true);  // Always black
  }


  // Draws two copies of the version bits (with its own error correction code),
  // based on this object's version field, iff 7 <= version <= 40.
  void drawVersion() {
    if (this.version < 7)
      return;

    // Calculate error correction code and pack bits
    int rem= this.version;  // version is uint6, in the range [7, 40]
    for (var i = 0; i < 12; i++)
      rem = (rem << 1) ^ ((rem >> 11) * 0x1F25);
    int bits = this.version << 12 | rem;  // uint18
    if (bits >> 18 != 0)
      throw "Assertion error";

    // Draw two copies
    for (var i = 0; i < 18; i++) {
      bool color = getBit(bits, i);
      int a = this.size - 11 + i % 3;
      int b = (i / 3).floor();
      this.setFunctionModule(a, b, color);
      this.setFunctionModule(b, a, color);
    }
  }


  // Draws a 9*9 finder pattern including the border separator,
  // with the center module at (x, y). Modules can be out of bounds.
  void drawFinderPattern(int x, int y) {
    for (var dy = -4; dy <= 4; dy++) {
      for (var dx = -4; dx <= 4; dx++) {
        int dist = max(dx.abs(), dy.abs());  // Chebyshev/infinity norm
        int xx = x + dx;
        int yy = y + dy;
        if (0 <= xx && xx < this.size && 0 <= yy && yy < this.size)
          this.setFunctionModule(xx, yy, dist != 2 && dist != 4);
      }
    }
  }


  // Draws a 5*5 alignment pattern, with the center module
  // at (x, y). All modules must be in bounds.
  void drawAlignmentPattern(int x, int y) {
    for (var dy = -2; dy <= 2; dy++) {
      for (var dx = -2; dx <= 2; dx++) {
        this.setFunctionModule(x + dx, y + dy, max(dx.abs(), dy.abs()) != 1);
      }
    }
  }


  // Sets the color of a module and marks it as a function module.
  // Only used by the constructor. Coordinates must be in bounds.
  void setFunctionModule(int x, int y, bool isBlack) {
    this.modules[y][x] = isBlack;
    this.isFunction[y][x] = true;
  }


  /*-- Private helper methods for constructor: Codewords and masking --*/

  // Returns a new byte string representing the given data with the appropriate error correction
  // codewords appended to it, based on this object's version and error correction level.
  List<int> addEccAndInterleave(List<int> data) {
    int ver = this.version;
    QrCodeEcc ecl = this.errorCorrectionLevel;
    if (data.length != QrCode.getNumDataCodewords(ver, ecl))
      throw "Invalid argument";

    // Calculate parameter numbers
    int numBlocks = QrCode.NUM_ERROR_CORRECTION_BLOCKS[ecl.ordinal][ver];
    int blockEccLen = QrCode.ECC_CODEWORDS_PER_BLOCK  [ecl.ordinal][ver];
    int rawCodewords = (QrCode.getNumRawDataModules(ver) / 8).floor();
    int numShortBlocks = numBlocks - rawCodewords % numBlocks;
    int shortBlockLen = (rawCodewords / numBlocks).floor();

    // Split data into blocks and append ECC to each block
    List<List<int>> blocks = [];
    List<int> rsDiv = QrCode.reedSolomonComputeDivisor(blockEccLen);
    for (var i = 0, k = 0; i < numBlocks; i++) {
      List<int> dat = data.sublist(k, k + shortBlockLen - blockEccLen + (i < numShortBlocks ? 0 : 1));
      k += dat.length;
      List<int> ecc = QrCode.reedSolomonComputeRemainder(dat, rsDiv);
      if (i < numShortBlocks)
        dat.add(0);
      dat.addAll(ecc);
      blocks.add(dat);
    }

    // Interleave (not concatenate) the bytes from every block into a single sequence
    List<int> result = [];
    for (var i = 0; i < blocks[0].length; i++) {
      blocks.asMap().forEach((j, block) {
        // Skip the padding byte in short blocks
        if (i != shortBlockLen - blockEccLen || j >= numShortBlocks)
          result.add(block[i]);
      });
    }
    if (result.length != rawCodewords)
      throw "Assertion error";
    return result;
  }


  // Draws the given sequence of 8-bit codewords (data and error correction) onto the entire
  // data area of this QR Code. Function modules need to be marked off before this is called.
  void drawCodewords(List<int> data) {
    if (data.length != (QrCode.getNumRawDataModules(this.version) / 8).floor())
      throw "Invalid argument";
    int i = 0;  // Bit index into the data
    // Do the funny zigzag scan
    for (var right = this.size - 1; right >= 1; right -= 2) {  // Index of right column in each column pair
      if (right == 6)
        right = 5;
      for (var vert = 0; vert < this.size; vert++) {  // Vertical counter
        for (var j = 0; j < 2; j++) {
          int x = right - j;  // Actual x coordinate
          bool upward = ((right + 1) & 2) == 0;
          int y = upward ? this.size - 1 - vert : vert;  // Actual y coordinate
          if (!this.isFunction[y][x] && i < data.length * 8) {
            this.modules[y][x] = getBit(data[i >> 3], 7 - (i & 7));
            i++;
          }
          // If this QR Code has any remainder bits (0 to 7), they were assigned as
          // 0/false/white by the constructor and are left unchanged by this method
        }
      }
    }
    if (i != data.length * 8)
      throw "Assertion error";
  }


  // XORs the codeword modules in this QR Code with the given mask pattern.
  // The function modules must be marked and the codeword bits must be drawn
  // before masking. Due to the arithmetic of XOR, calling applyMask() with
  // the same mask value a second time will undo the mask. A final well-formed
  // QR Code needs exactly one (not zero, two, etc.) mask applied.
  void applyMask(int mask) {
    if (mask < 0 || mask > 7)
      throw "Mask value out of range";
    for (var y = 0; y < this.size; y++) {
      for (var x = 0; x < this.size; x++) {
        bool invert;
        switch (mask) {
          case 0:  invert = (x + y) % 2 == 0;                              break;
          case 1:  invert = y % 2 == 0;                                    break;
          case 2:  invert = x % 3 == 0;                                    break;
          case 3:  invert = (x + y) % 3 == 0;                              break;
          case 4:  invert = ((x / 3).floor() + (y / 2).floor()) % 2 == 0;  break;
          case 5:  invert = x * y % 2 + x * y % 3 == 0;                    break;
          case 6:  invert = (x * y % 2 + x * y % 3) % 2 == 0;              break;
          case 7:  invert = ((x + y) % 2 + x * y % 3) % 2 == 0;            break;
          default:  throw "Assertion error";
        }
        if (!this.isFunction[y][x] && invert)
        this.modules[y][x] = !this.modules[y][x];
      }
    }
  }


  // Calculates and returns the penalty score based on state of this QR Code's current modules.
  // This is used by the automatic mask choice algorithm to find the mask pattern that yields the lowest score.
  int getPenaltyScore() {
    int result = 0;

    // Adjacent modules in row having same color, and finder-like patterns
    for (var y = 0; y < this.size; y++) {
      var runColor = false;
      var runX = 0;
      var runHistory = [0,0,0,0,0,0,0];
      for (var x = 0; x < this.size; x++) {
        if (this.modules[y][x] == runColor) {
          runX++;
          if (runX == 5)
          result += QrCode.PENALTY_N1;
          else if (runX > 5)
          result++;
        } else {
          this.finderPenaltyAddHistory(runX, runHistory);
          if (!runColor)
            result += this.finderPenaltyCountPatterns(runHistory) * QrCode.PENALTY_N3;
          runColor = this.modules[y][x];
          runX = 1;
        }
      }
      result += this.finderPenaltyTerminateAndCount(runColor, runX, runHistory) * QrCode.PENALTY_N3;
    }
    // Adjacent modules in column having same color, and finder-like patterns
    for (var x = 0; x < this.size; x++) {
      var runColor = false;
      var runY = 0;
      var runHistory = [0,0,0,0,0,0,0];
      for (var y = 0; y < this.size; y++) {
        if (this.modules[y][x] == runColor) {
          runY++;
          if (runY == 5)
          result += QrCode.PENALTY_N1;
          else if (runY > 5)
          result++;
        } else {
          this.finderPenaltyAddHistory(runY, runHistory);
          if (!runColor)
            result += this.finderPenaltyCountPatterns(runHistory) * QrCode.PENALTY_N3;
          runColor = this.modules[y][x];
          runY = 1;
        }
      }
      result += this.finderPenaltyTerminateAndCount(runColor, runY, runHistory) * QrCode.PENALTY_N3;
    }

    // 2*2 blocks of modules having same color
    for (var y = 0; y < this.size - 1; y++) {
      for (var x = 0; x < this.size - 1; x++) {
        bool color = this.modules[y][x];
        if (color == this.modules[y][x + 1] &&
        color == this.modules[y + 1][x] &&
        color == this.modules[y + 1][x + 1])
          result += QrCode.PENALTY_N2;
      }
    }

    // Balance of black and white modules
    int black = 0;
    for (var row in this.modules) {
      for (var color in row) {
        if (color) {
          black++;
        }
      }
    }
    int total = this.size * this.size;  // Note that size is odd, so black/total != 1/2
    // Compute the smallest integer k >= 0 such that (45-5k)% <= black/total <= (55+5k)%
    int k = ((black * 20 - total * 10).abs() / total).ceil() - 1;
    result += k * QrCode.PENALTY_N4;
    return result;
  }


  /*-- Private helper functions --*/

  // Returns an ascending list of positions of alignment patterns for this version number.
  // Each position is in the range [0,177), and are used on both the x and y axes.
  // This could be implemented as lookup table of 40 variable-length lists of integers.
  List<int> getAlignmentPatternPositions() {
    if (this.version == 1) {
     return [];
    } else {
    int numAlign = (this.version / 7).floor() + 2;
    int step = (this.version == 32) ? 26 :
    ((this.size - 13) / (numAlign*2 - 2)).ceil() * 2;
    List<int> result = [6];
    for (var pos = this.size - 7; result.length < numAlign; pos -= step)
      splice(result, 1, 0, pos);
      return result;
    }
  }


  // Returns the number of data bits that can be stored in a QR Code of the given version number, after
  // all function modules are excluded. This includes remainder bits, so it might not be a multiple of 8.
  // The result is in the range [208, 29648]. This could be implemented as a 40-entry lookup table.
  static int getNumRawDataModules(int ver) {
    if (ver < QrCode.MIN_VERSION || ver > QrCode.MAX_VERSION)
      throw "Version number out of range";
    int result = (16 * ver + 128) * ver + 64;
    if (ver >= 2) {
      int numAlign = (ver / 7).floor() + 2;
      result -= (25 * numAlign - 10) * numAlign - 55;
      if (ver >= 7)
        result -= 36;
    }
    if (!(208 <= result && result <= 29648))
      throw "Assertion error";
    return result;
  }


  // Returns the number of 8-bit data (i.e. not error correction) codewords contained in any
  // QR Code of the given version number and error correction level, with remainder bits discarded.
  // This stateless pure function could be implemented as a (40*4)-cell lookup table.
  static int getNumDataCodewords(int ver, QrCodeEcc ecl) {
    return (QrCode.getNumRawDataModules(ver) / 8).floor() -
      QrCode.ECC_CODEWORDS_PER_BLOCK    [ecl.ordinal][ver] *
      QrCode.NUM_ERROR_CORRECTION_BLOCKS[ecl.ordinal][ver];
  }


  // Returns a Reed-Solomon ECC generator polynomial for the given degree. This could be
  // implemented as a lookup table over all possible parameter values, instead of as an algorithm.
  static List<int> reedSolomonComputeDivisor(int degree) {
    if (degree < 1 || degree > 255)
      throw "Degree out of range";
    // Polynomial coefficients are stored from highest to lowest power, excluding the leading term which is always 1.
    // For example the polynomial x^3 + 255x^2 + 8x + 93 is stored as the uint8 array [255, 8, 93].
    List<int> result = [];
    for (var i = 0; i < degree - 1; i++)
      result.add(0);
    result.add(1);  // Start off with the monomial x^0

    // Compute the product polynomial (x - r^0) * (x - r^1) * (x - r^2) * ... * (x - r^{degree-1}),
    // and drop the highest monomial term which is always 1x^degree.
    // Note that r = 0x02, which is a generator element of this field GF(2^8/0x11D).
    var root = 1;
    for (var i = 0; i < degree; i++) {
      // Multiply the current product by (x - r^i)
      for (var j = 0; j < result.length; j++) {
        result[j] = QrCode.reedSolomonMultiply(result[j], root);
        if (j + 1 < result.length)
          result[j] ^= result[j + 1];
      }
      root = QrCode.reedSolomonMultiply(root, 0x02);
    }
    return result;
  }


  // Returns the Reed-Solomon error correction codeword for the given data and divisor polynomials.
  static List<int> reedSolomonComputeRemainder(List<int> data, List<int> divisor) {
    List<int> result = divisor.map((_) => 0).toList();
    for (var b in data) {  // Polynomial division
      int factor = b ^ result.removeAt(0);
      result.add(0);
      divisor.asMap().forEach((i, coef) =>
      result[i] ^= QrCode.reedSolomonMultiply(coef, factor));
    }
    return result;
  }


  // Returns the product of the two given field elements modulo GF(2^8/0x11D). The arguments and result
  // are unsigned 8-bit integers. This could be implemented as a lookup table of 256*256 entries of uint8.
  static int reedSolomonMultiply(int x, int y) {
    if (x >> 8 != 0 || y >> 8 != 0)
      throw "Byte out of range";
    // Russian peasant multiplication
    int z = 0;
    for (var i = 7; i >= 0; i--) {
      z = (z << 1) ^ ((z >> 7) * 0x11D);
      z ^= ((y >> i) & 1) * x;
    }
    if (z >> 8 != 0)
      throw "Assertion error";
    return z;
  }


  // Can only be called immediately after a white run is added, and
  // returns either 0, 1, or 2. A helper function for getPenaltyScore().
  int finderPenaltyCountPatterns(List<int> runHistory) {
    int n = runHistory[1];
    if (n > this.size * 3)
      throw "Assertion error";
    bool core = n > 0 && runHistory[2] == n && runHistory[3] == n * 3 && runHistory[4] == n && runHistory[5] == n;
    return (core && runHistory[0] >= n * 4 && runHistory[6] >= n ? 1 : 0)
    + (core && runHistory[6] >= n * 4 && runHistory[0] >= n ? 1 : 0);
  }


  // Must be called at the end of a line (row or column) of modules. A helper function for getPenaltyScore().
  int finderPenaltyTerminateAndCount(bool currentRunColor, int currentRunLength, List<int> runHistory) {
  if (currentRunColor) {  // Terminate black run
    this.finderPenaltyAddHistory(currentRunLength, runHistory);
    currentRunLength = 0;
  }
  currentRunLength += this.size;  // Add white border to final run
  this.finderPenaltyAddHistory(currentRunLength, runHistory);
  return this.finderPenaltyCountPatterns(runHistory);
  }


  // Pushes the given value to the front and drops the last value. A helper function for getPenaltyScore().
  void finderPenaltyAddHistory(int currentRunLength, List<int> runHistory) {
    if (runHistory[0] == 0)
      currentRunLength += this.size;  // Add white border to initial run
    runHistory.removeLast();
    runHistory.insert(0, currentRunLength);
  }
}

class QrSegment {
  /*-- Static factory functions (mid level) --*/

  // Returns a segment representing the given binary data encoded in
  // byte mode. All input byte arrays are acceptable. Any text string
  // can be converted to UTF-8 bytes and encoded as a byte mode segment.
  static QrSegment makeBytes(List<int> data) {
    List<int> bb = [];
    for (var b in data)
      appendBits(b, 8, bb);
    return QrSegment(QrSegmentMode.BYTE, data.length, bb);
  }

  // Returns a segment representing the given string of decimal digits encoded in numeric mode.
  static QrSegment makeNumeric(String digits) {
    if (!NUMERIC_REGEX.hasMatch(digits))
      throw "String contains non-numeric characters";
    List<int> bb = [];
    for (var i = 0; i < digits.length; ) {  // Consume up to 3 digits per iteration
      int n = min(digits.length - i, 3);
      appendBits(int.parse(digits.substring(i, i+n)), n * 3 + 1, bb);
      i += n;
    }
    return QrSegment(QrSegmentMode.NUMERIC, digits.length, bb);
  }


  // Returns a segment representing the given text string encoded in alphanumeric mode.
  // The characters allowed are: 0 to 9, A to Z (uppercase only), space,
  // dollar, percent, asterisk, plus, hyphen, period, slash, colon.
  static QrSegment makeAlphanumeric(String text) {
    if (!ALPHANUMERIC_REGEX.hasMatch(text))
      throw "String contains unencodable characters in alphanumeric mode";
    List<int> bb = [];
    int i;
    for (i = 0; i + 2 <= text.length; i += 2) {  // Process groups of 2
      var temp = QrSegment.ALPHANUMERIC_CHARSET.indexOf(text.substring(i, 1)) * 45;
      temp += QrSegment.ALPHANUMERIC_CHARSET.indexOf(text.substring(i + 1, 1));
      appendBits(temp, 11, bb);
    }
    if (i < text.length)  // 1 character remaining
      appendBits(QrSegment.ALPHANUMERIC_CHARSET.indexOf(text.substring(i, 1)), 6, bb);
    return QrSegment(QrSegmentMode.ALPHANUMERIC, text.length, bb);
  }


  // Returns a new mutable list of zero or more segments to represent the given Unicode text string.
  // The result may use various segment modes and switch modes to optimize the length of the bit stream.
  static List<QrSegment> makeSegments(String text) {
    // Select the most efficient segment encoding automatically
    if (text == "")
      return [];
    else if (NUMERIC_REGEX.hasMatch(text))
      return [QrSegment.makeNumeric(text)];
    else if (ALPHANUMERIC_REGEX.hasMatch(text))
      return [QrSegment.makeAlphanumeric(text)];
    else
      return [QrSegment.makeBytes(QrSegment.toUtf8ByteArray(text))];
  }


  // Returns a segment representing an Extended Channel Interpretation
  // (ECI) designator with the given assignment value.
  static QrSegment makeEci(int assignVal) {
    List<int> bb = [];
    if (assignVal < 0) {
      throw "ECI assignment value out of range";
    } else if (assignVal < (1 << 7)) {
      appendBits(assignVal, 8, bb);
    } else if (assignVal < (1 << 14)) {
      appendBits(2, 2, bb);
      appendBits(assignVal, 14, bb);
    } else if (assignVal < 1000000) {
    appendBits(6, 3, bb);
    appendBits(assignVal, 21, bb);
    } else {
      throw "ECI assignment value out of range";
    }
    return QrSegment(QrSegmentMode.ECI, 0, bb);
  }


  /*-- Constructor (low `level) `and fields --*/

  // The mode indicator of this segment.
  final QrSegmentMode mode;

  // The length of this segment's unencoded data. Measured in characters for
  // numeric/alphanumeric/kanji mode, bytes for byte mode, and 0 for ECI mode.
  // Always zero or positive. Not the same as the data's bit length.
  final int numChars;

  // The data bits of this segment. Accessed through getData().
  final List<int> bitData;

  // Creates a new QR Code segment with the given attributes and data.
  // The character count (numChars) must agree with the mode and the bit buffer length,
  // but the constraint isn't checked. The given bit buffer is cloned and stored.
  QrSegment(this.mode, this.numChars, this.bitData) {
    if (numChars < 0)
      throw "Invalid argument";
  }


  /*-- Methods --*/

  // Returns a new copy of the data bits of this segment.
  List<int> getData() {
    return this.bitData;  // Make defensive copy
  }


  // (Package-private) Calculates and returns the number of bits needed to encode the given segments at
  // the given version. The result is infinity if a segment has too many characters to fit its length field.
  static int getTotalBits(List<QrSegment> segs, int version) {
    int result = 0;
    for (var seg in segs) {
      int ccbits = seg.mode.numCharCountBits(version);
      if (seg.numChars >= (1 << ccbits))
        return -1;  // The segment's length doesn't fit the field's bit width
      result += 4 + ccbits + seg.bitData.length;
    }
    return result;
  }


  // Returns a new array of bytes representing the given string encoded in UTF-8.
  static List<int> toUtf8ByteArray(String str) {
    return utf8.encode(str);
  }


  /*-- Constants --*/

  // Describes precisely all strings that are encodable in numeric mode. To test
  // whether a string s is encodable: let ok: boolean = NUMERIC_REGEX.test(s);
  // A string is encodable iff each character is in the range 0 to 9.
  static RegExp NUMERIC_REGEX = RegExp(r'^[0-9]*$');

  // Describes precisely all strings that are encodable in alphanumeric mode. To test
  // whether a string s is encodable: let ok: boolean = ALPHANUMERIC_REGEX.test(s);
  // A string is encodable iff each character is in the following set: 0 to 9, A to Z
  // (uppercase only), space, dollar, percent, asterisk, plus, hyphen, period, slash, colon.
  static RegExp ALPHANUMERIC_REGEX = RegExp(r'^[A-Z0-9 $%*+.\/:-]*$');

  // The set of all legal characters in alphanumeric mode,
  // where each character value maps to the index in the string.
  static const String ALPHANUMERIC_CHARSET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ \$%*+-./:";
}

class QrCodeEcc {
  static const QrCodeEcc LOW      = QrCodeEcc(0, 1);
  static const QrCodeEcc MEDIUM   = QrCodeEcc(1, 0);
  static const QrCodeEcc QUARTILE = QrCodeEcc(2, 3);
  static const QrCodeEcc HIGH     = QrCodeEcc(3, 2);

  final int ordinal;
  final int formatBits;

  const QrCodeEcc(this.ordinal, this.formatBits);
}

class QrSegmentMode {

  /*-- Constants --*/

  static const QrSegmentMode NUMERIC      = QrSegmentMode(0x1, [10, 12, 14]);
  static const QrSegmentMode ALPHANUMERIC = QrSegmentMode(0x2, [ 9, 11, 13]);
  static const QrSegmentMode BYTE         = QrSegmentMode(0x4, [ 8, 16, 16]);
  static const QrSegmentMode KANJI        = QrSegmentMode(0x8, [ 8, 10, 12]);
  static const QrSegmentMode ECI          = QrSegmentMode(0x7, [ 0,  0,  0]);

  /*-- Constructor and fields --*/

  // The mode indicator bits, which is a uint4 value (range 0 to 15).
  final int modeBits;

  // Number of character count bits for three different version ranges.
  final dynamic numBitsCharCount;

  const QrSegmentMode(this.modeBits, this.numBitsCharCount);

  /*-- Method --*/

  // (Package-private) Returns the bit width of the character count field for a segment in
  // this mode in a QR Code at the given version number. The result is in the range [0, 16].
  int numCharCountBits(int ver) {
    return this.numBitsCharCount[((ver + 7) / 17).floor()];
  }
}
