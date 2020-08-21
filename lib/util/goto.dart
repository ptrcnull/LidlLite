import 'package:flutter/material.dart';

void goto(BuildContext context, Widget screen) {
  Navigator.of(context).pushReplacement(MaterialPageRoute(
    builder: (context) => screen,
  ));
}

Future<dynamic> push(BuildContext context, Widget screen) {
  return Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => screen
  ));
}
