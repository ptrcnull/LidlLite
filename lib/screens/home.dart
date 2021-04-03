import 'package:flutter/material.dart';

import 'package:lidl_lite/prefs.dart';
import 'package:lidl_lite/screens/login.dart';
import 'package:lidl_lite/util/goto.dart';
import 'package:lidl_lite/widgets/lidl_pay_card.dart';
import 'package:lidl_lite/widgets/lidl_plus_card.dart';
import 'package:lidl_lite/widgets/person_data_card.dart';
import 'package:lidl_lite/widgets/token_expiry_card.dart';

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
