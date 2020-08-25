import 'package:LidlLite/widgets/card_tile.dart';
import 'package:flutter/material.dart';

import 'package:LidlLite/api/client.dart';
import 'package:LidlLite/prefs.dart';
import 'package:LidlLite/screens/show_code.dart';
import 'package:LidlLite/util/goto.dart';

class LidlPlusCard extends StatelessWidget {
  Future<String> getLoyaltyCard() async {
    if (await Prefs.hasString('loyaltyNumber')) {
      return Prefs.getString('loyaltyNumber');
    } else {
      var profile = await api.getProfile();
      if (isNotEmpty(profile['loyaltyId'])) {
        await Prefs.setString('loyaltyNumber', profile['loyaltyId']);
        return profile['loyaltyId'];
      }
      throw new Exception('Failed to get loyalty card number');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: FutureBuilder(
        future: getLoyaltyCard(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return InkWell(
              splashColor: Colors.white.withAlpha(30),
              onTap: () {
                var data = api.cred.idToken.claims;
                push(context, ShowCodeScreen(
                  snapshot.data,
                  loggedIn: true,
                  name: data.name + ' ' + data.familyName,
                ));
              },
              child: CardTile(
                leading: Icon(Icons.card_membership),
                title: Text('Lidl Plus card'),
                subtitle: Text('Click to open'),
              ),
            );
          } else if (snapshot.hasError) {
            return CardTile(
              leading: Icon(Icons.warning),
              title: Text('Error'),
              subtitle: Text(snapshot.error.toString())
            );
          } else {
            return LinearProgressIndicator();
          }
        },
      )
    );
  }
}
