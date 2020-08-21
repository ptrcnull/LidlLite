import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final dynamic err;

  ErrorDialog(this.err);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Error'),
      content: Text(err.toString()),
      actions: [
        FlatButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
