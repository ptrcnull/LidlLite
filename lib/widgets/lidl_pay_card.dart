import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:lidl_lite/prefs.dart';
import 'package:lidl_lite/util/goto.dart';
import 'package:lidl_lite/api/client.dart';
import 'package:lidl_lite/api/models/lidl_pay_card.dart';
import 'package:lidl_lite/screens/show_code.dart';
import 'package:lidl_lite/widgets/card_tile.dart';

class LidlPayCard extends StatelessWidget {
  Future<List<LidlPayCardModel>> getLidlPayCards() async {
    if (await Prefs.has('lidlPayCards')) {
      List<String> stringList = await Prefs.getList('lidlPayCards');
      return stringList.map((card) {
        return LidlPayCardModel.fromJson(jsonDecode(card));
      }).toList();
    } else {
      var cards = await api.getCards();
      await Prefs.setList(
          'lidlPayCards',
          cards.map((card) => jsonEncode(card.asJson())).toList()
      );
      return cards;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getLidlPayCards(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<LidlPayCardModel> cards = snapshot.data;
          return Card(
            child: Column(
              children: [
                CardTile(
                  leading: Icon(Icons.credit_card),
                  title: Text('Lidl Pay'),
                  subtitle: Text(cards.length.toString() + ' card(s) loaded'),
                ),
                for (var card in cards) InkWell(
                  splashColor: Colors.white.withAlpha(30),
                  onTap: () {
                    var data = api.cred.token.idToken.claims;
                    push(context, ShowCodeScreen(
                      api.getQR(card.loyaltyId),
                      loggedIn: true,
                      lidlPay: true,
                      name: data.name + ' ' + data.familyName,
                    ));
                  },
                  child: Card(
                    color: Colors.white24,
                    child: CardTile(
                      leading: SvgPicture.asset(
                        'assets/visa.svg',
                        width: 32,
                      ),
                      title: Text(card.alias + ' ' + card.number),
                      subtitle: Text('Click to open'),
                    )
                  ),
                )
              ],
            )
          );
        } else if (snapshot.hasError) {
          return Card(
            child: CardTile(
              leading: Icon(Icons.warning),
              title: Text('Error'),
              subtitle: Text(snapshot.error.toString()),
            ),
          );
        } else {
          return LinearProgressIndicator();
        }
      },
    );
  }
}
