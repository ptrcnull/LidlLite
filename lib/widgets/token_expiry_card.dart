import 'dart:convert';

import 'package:LidlLite/prefs.dart';
import 'package:LidlLite/widgets/card_tile.dart';
import 'package:LidlLite/widgets/error_dialog.dart';
import 'package:flutter/material.dart';

import 'package:duration/duration.dart';

import 'package:LidlLite/util/openid.dart';

class TokenExpiryCard extends StatefulWidget {
  final Credential cred;

  TokenExpiryCard(this.cred);

  _TokenExpiryCardState createState() => _TokenExpiryCardState();
}

class _TokenExpiryCardState extends State<TokenExpiryCard> {
  @override
  Widget build(BuildContext context) {
    var diff = widget.cred.token.expiresAt.difference(DateTime.now());
    var expired = diff.isNegative;

    var duration = prettyDuration(
      diff,
      delimiter: ', ',
      conjunction: ' and '
    );

    Future.delayed(Duration(seconds: 1)).then((value) {
      if (mounted) {
        setState(() {});
      }
    });

    return Card(
      child: InkWell(
        splashColor: Colors.white.withAlpha(30),
        onTap: () async {
          try {
            await widget.cred.getTokenResponse(true);
            await Prefs.setString('credentials', jsonEncode(widget.cred.toJson()));
          } catch (err) {
            showDialog(
              context: context,
              builder: (context) => ErrorDialog(err)
            );
          }
        },
        child: expired
        ? CardTile(
            leading: Icon(Icons.vpn_key),
            title: Text('Token expired'),
            subtitle: Text('Click to refresh')
        )
        : CardTile(
          leading: Icon(Icons.vpn_key),
          title: Text('Token expires in...'),
          subtitle: Text(duration)
        )
      )
    );
  }

}
