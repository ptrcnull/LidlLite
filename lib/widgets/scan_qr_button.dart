import 'package:LidlLite/util/goto.dart';
import 'package:flutter/material.dart';

import 'package:qrscan/qrscan.dart' as scanner;

import 'package:LidlLite/screens/show_code.dart';
import 'package:LidlLite/prefs.dart';

bool isNumeric(String char) {
  return 48 <= char.codeUnitAt(0) && char.codeUnitAt(0) <= 57;
}

class ScanQRButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlineButton(
      child: Text('Scan QR'),
      onPressed: () async {
        var result = await scanner.scan();

        var snack = (result) => Scaffold.of(context).showSnackBar(
          SnackBar(content: Text(result)));

        if (result is String) {
          if (result.characters.every(isNumeric)) {
            if (result.length == 17) {
              Prefs.setString('lidlPlusCode', result);
              goto(context, ShowCodeScreen(result));
              return;
            }
            if (result.length == 38) {
              Prefs.setString('lidlPayCode', result);
              goto(context, ShowCodeScreen(result, lidlPay: true));
              return;
            }
          }

          snack('Invalid QR code scanned');
          return;
        }
      },
    );
  }
}
