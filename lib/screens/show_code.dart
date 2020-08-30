import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import 'package:LidlLite/prefs.dart';
import 'package:LidlLite/util/goto.dart';
import 'package:LidlLite/screens/login.dart';
import 'package:LidlLite/widgets/card_container.dart';


const lightBlue = Color(0xFF63BEFA);
const blue = Color(0xFF0076BF);
const darkBlue = Color(0xFF00507F);

const lidlPlusGradientColors = [ blue, darkBlue ];
const lidlPayGradientColors = [ lightBlue, blue ];

String reformatLidlPayCode(String code) {
  return code.substring(0, 17) +
    DateFormat('ddMMyyyyHHmm').format(DateTime.now().toUtc()) +
    + '01' + code.substring(31);
}

class ShowCodeScreen extends StatefulWidget {
  final dynamic code;
  final int coupons;
  final bool lidlPay;
  final bool loggedIn;
  final String name;

  ShowCodeScreen(dynamic _code, {
    this.coupons = 0,
    this.lidlPay = false,
    this.loggedIn = false,
    this.name = 'Name Surname'}): this.code = (lidlPay && !loggedIn)
      ? reformatLidlPayCode(_code)
      : _code;

  @override
  _ShowCodeScreenState createState() => _ShowCodeScreenState(code);
}

class _ShowCodeScreenState extends State<ShowCodeScreen> {
  dynamic code;

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
    var gradient = LinearGradient(
      colors: widget.lidlPay ? lidlPayGradientColors : lidlPlusGradientColors,
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter
    );

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
                    code is String
                      ? CardContainer(code, widget.name)
                      : FutureBuilder(
                        future: code,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return CardContainer(snapshot.data, widget.name);
                          } else if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          } else {
                            return Center(child: CircularProgressIndicator());
                          }
                        },
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
