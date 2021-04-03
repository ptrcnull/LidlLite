import 'package:flutter/material.dart';

import 'package:lidl_lite/widgets/scan_qr_button.dart';
import 'package:lidl_lite/widgets/log_in_button.dart';

class LoginScreen extends StatelessWidget {
  final GlobalKey scaffoldChildKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lidl Lite'),
      ),
      body: Center(
        key: scaffoldChildKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            SizedBox(

            ),
            Text('lidl prosze nie pozwijcie mnie'),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ScanQRButton(),
                  LogInButton(scaffoldChildKey)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}