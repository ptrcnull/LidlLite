import 'package:flutter/material.dart';

class CardTile extends ListTile {
  final Widget leading;
  final Widget title;
  final Widget subtitle;

  CardTile({leading, this.title, this.subtitle}): leading = Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      leading
    ],
  );
}