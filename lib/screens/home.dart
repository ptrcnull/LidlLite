import 'package:flutter/material.dart';

import 'package:LidlLite/prefs.dart';
import 'package:LidlLite/screens/login.dart';
import 'package:LidlLite/util/goto.dart';
import 'package:LidlLite/widgets/lidl_pay_card.dart';
import 'package:LidlLite/widgets/lidl_plus_card.dart';
import 'package:LidlLite/widgets/person_data_card.dart';
import 'package:LidlLite/widgets/token_expiry_card.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lidl Lite'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) async {
              if (result == 'logOut') {
                for (var key in await Prefs.getKeys()) {
                  await Prefs.setString(key, null);
                }
                goto(context, LoginScreen());
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logOut',
                child: Text('Log out'),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          UserDataCard(),
          TokenExpiryCard(),
          LidlPlusCard(),
          LidlPayCard(),
        ],
      ),
    );
  }
}
