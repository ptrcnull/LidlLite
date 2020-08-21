import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:LidlLite/prefs.dart';
import 'package:LidlLite/screens/login.dart';
import 'package:LidlLite/util/goto.dart';
import 'package:flutter/material.dart';


const lightBlue = Color(0xFF63BEFA);
const blue = Color(0xFF0076BF);
const darkBlue = Color(0xFF00507F);

const lidlPlusGradientColors = [ blue, darkBlue ];
const lidlPayGradientColors = [ lightBlue, blue ];

String reformatLidlPayCode(String code) {
  return code.substring(0, 17) +
    DateFormat('ddMMyyHHmmss').format(DateTime.now().toUtc()) +
    code.substring(29);
}

class ShowCodeScreen extends StatefulWidget {
  final String code;
  final int coupons;
  final bool lidlPay;
  final bool loggedIn;

  ShowCodeScreen(String _code, {
    this.coupons = 0,
    this.lidlPay = false,
    this.loggedIn = false}): this.code = (lidlPay && !loggedIn)
      ? reformatLidlPayCode(_code)
      : _code;

  @override
  _ShowCodeScreenState createState() => _ShowCodeScreenState(code);
}

class _ShowCodeScreenState extends State<ShowCodeScreen> {
  String code;

  _ShowCodeScreenState(this.code);

  void showExitDialog(context) {
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () { Navigator.of(context).pop(); },
    );
    Widget continueButton = FlatButton(
      child: Text("Continue"),
      onPressed: () async {
        Navigator.of(context).pop();
        await Prefs.setString(widget.lidlPay ? 'lidlPayCode' : 'lidlPlusCode', null);
        goto(context, LoginScreen());
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Confirm"),
      content: Text("Are sure you want to exit?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    showDialog(context: context, builder: (context) => alert);
  }

  @override
  Widget build(BuildContext context) {
    var cardWidth = (MediaQuery.of(context).size.width - 20);
    var cardHeight = cardWidth * 0.7;
    var cardPadding = 15;
    var qrPadding = (cardHeight - (cardPadding * 2) - 120) / 2;

    var gradient = LinearGradient(
      colors: widget.lidlPay ? lidlPayGradientColors : lidlPlusGradientColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter
    );

    print("Showing code:");
    print(code);

    if (widget.lidlPay && !widget.loggedIn) {
      Future.delayed(Duration(seconds: 30)).then((value) {
        if (this.mounted) {
          setState(() {
            code = reformatLidlPayCode(code);
          });
        }
      });
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        foregroundColor: blue,
        backgroundColor: Colors.white,
        icon: Icon(Icons.close),
        label: Text('ZAMKNIJ', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () {
          if (widget.loggedIn) {
            Navigator.of(context).pop();
          } else {
            showExitDialog(context);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Container(
        decoration: BoxDecoration(
          gradient: gradient
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(10, 100, 10, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Karta Lidl ' + (widget.lidlPay ? 'Pay' : 'Plus'),
                      style: TextStyle(
                        fontSize: 32.0,
                        fontFamily: 'Museo Sans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      width: cardWidth,
                      height: cardHeight,
                      margin: EdgeInsets.only(top: 20),
                      padding: EdgeInsets.all(cardPadding.toDouble()),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: qrPadding),
                            child: Center(
                              child: QrImage(
                                data: code,
                                version: QrVersions.auto,
                                size: 120.0,
                              ),
                            )
                          ),
                          Spacer(),
                          Padding(
                            padding: EdgeInsets.only(bottom: 5),
                            child: Text(
                              'Patrycja Rosa',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Text(
                            code.substring(0, 17),
                            style: TextStyle(
                              color: Colors.black38,
                              fontSize: 10.0,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ]
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 20, bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Aktywowane kupony: ' + widget.coupons.toString(),
                            textAlign: TextAlign.center,
                          )
                        ],
                      )
                    ),
                  ],
                )
              ),
              Container(
                padding: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white),
                    bottom: BorderSide(color: Colors.white),
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      )
                    ),
                    Text(
                      'Zapłać Lidl Pay',
                      style: TextStyle(fontSize: 16)
                    ),
                    Spacer(),
                    Switch(
                      value: widget.lidlPay,
                      onChanged: (bool value) {},
                    )
                  ]
                )
              )
            ],
          )
        )
      )
    );
  }
}
