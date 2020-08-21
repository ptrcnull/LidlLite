import 'package:LidlLite/widgets/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:openid_client/openid_client.dart';

class UserDataCard extends StatelessWidget {
  final OpenIdClaims data;

  UserDataCard(this.data);

  @override
  Widget build(BuildContext context) {
    print(data);
    return Card(
      child: CardTile(
        leading: Icon(Icons.person),
        title: Text(data.name + ' ' + data.familyName),
        subtitle: Text(data.email)
      ),
    );
  }
}