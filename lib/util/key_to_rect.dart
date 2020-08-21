import 'package:flutter/material.dart';

Rect keyToRect(GlobalKey key) {
  RenderBox renderBox = key.currentContext.findRenderObject();
  var size = renderBox.size;
  var offset = renderBox.localToGlobal(Offset.zero);

  return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
}