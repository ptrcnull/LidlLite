import 'package:flutter/material.dart';

import 'package:openid_client/openid_client.dart';

import 'package:lidl_lite/api/client.dart';
import 'package:lidl_lite/widgets/card_tile.dart';

class UserDataCard extends StatelessWidget {
  final OpenIdClaims data = api.cred.token.idToken.claims;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CardTile(
        leading: Icon(Icons.person),
        title: Text(data.name + ' ' + data.familyName),
        subtitle: Text(data.email)
      ),
    );
  }
}