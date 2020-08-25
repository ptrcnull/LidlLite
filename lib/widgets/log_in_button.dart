import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

import 'package:LidlLite/api/client.dart';
import 'package:LidlLite/prefs.dart';
import 'package:LidlLite/util/goto.dart';
import 'package:LidlLite/util/openid.dart';
import 'package:LidlLite/util/key_to_rect.dart';
import 'package:LidlLite/screens/home.dart';
import 'package:LidlLite/widgets/error_dialog.dart';

class LogInButton extends StatelessWidget {
  final GlobalKey scaffoldChildKey;

  LogInButton(this.scaffoldChildKey);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Colors.blue,
      textColor: Colors.white,
      child: Text('Log in'),
      onPressed: () async {
        var openid = OpenIDResolver();
        var url = await openid.getURL();

        var webview = FlutterWebviewPlugin();
        webview.launch(url,
            rect: keyToRect(scaffoldChildKey),
            clearCookies: true);
        webview.onUrlChanged.listen((String url) async {
          if (url.startsWith('com.lidlplus.app://')) {
            webview.close();
            var uri = Uri.parse(url);

            var openIdCred;
            try {
              openIdCred = await openid.getCredential(
                  uri.queryParameters['code']);
            } catch (err) {
              showDialog(
                  context: context,
                  builder: (context) => ErrorDialog(err)
              );
            }
            var cred = Credential.fromJson(openIdCred.toJson());

            await Prefs.setString('credentials', jsonEncode(cred.toJson()));
            api.cred = cred;

            var success = await api.init();
            if (!success) {
              showDialog(
                context: context,
                builder: (context) => ErrorDialog(
                  Exception('Failed to init app\nSee logs for more info.')
                )
              );
            }

            goto(context, HomeScreen());
          }
        });
      },
    );
  }
}
