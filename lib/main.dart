import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:lidl_lite/prefs.dart';
import 'package:lidl_lite/api/client.dart';
import 'package:lidl_lite/util/goto.dart';
import 'package:lidl_lite/util/openid.dart';
import 'package:lidl_lite/screens/login.dart';
import 'package:lidl_lite/screens/show_code.dart';
import 'package:lidl_lite/screens/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lidl Lite',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Museo Sans'
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Museo Sans'
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class CurrentScreenData {
  final String screen;
  final Map<String, String> context;

  CurrentScreenData({this.screen, this.context});
}

class _MyHomePageState extends State<MyHomePage> {
  void navigate(BuildContext context) async {
    await Prefs.init();

    if (await Prefs.hasString('lidlPlusCode')) {
      goto(context, ShowCodeScreen(await Prefs.getString('lidlPlusCode')));
      return;
    }

    if (await Prefs.hasString('lidlPayCode')) {
      goto(context, ShowCodeScreen(await Prefs.getString('lidlPayCode'), lidlPay: true));
      return;
    }

    if (await Prefs.hasString('credentials')) {
      var cred = Credential.fromJson(jsonDecode(await Prefs.getString('credentials')));
      api.cred = cred;
      goto(context, HomeScreen());
      return;
    }

    goto(context, LoginScreen());
  }

  @override
  Widget build(BuildContext context) {
    navigate(context);
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
