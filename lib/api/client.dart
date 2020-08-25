import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:LidlLite/api/models/lidl_pay_card.dart';
import 'package:LidlLite/util/device_id.dart';
import 'package:LidlLite/util/openid.dart';

const AppGatewayURL = 'https://appgateway.lidlplus.com/';
const PaymentsURL = 'https://payments.lidlplus.com/';

var api = ApiClient();

class ApiClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  Credential cred;

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['authorization'] = 'Bearer ' + cred.token.accessToken ?? '';

    request.headers['app'] = 'com.lidl.eci.lidlplus';
    request.headers['app-version'] = '14.24.2';
    request.headers['operating-system'] = 'Android';
    request.headers['countryv1model'] = 'PL';
    request.headers['deviceid'] = await getDeviceID();

    return _inner.send(request);
  }

  Future<bool> init() async {
    var res = await post(AppGatewayURL + 'app/v21/PL/init?appVersion=14.24.2');
    var body = jsonDecode(res.body);
    return body['code'] == 'RESULT_I40_01';
  }

  Future<Map<String, dynamic>> getProfile() async {
    var res = await post(AppGatewayURL + 'app/v21/PL/contacts/lidlplusprofile',
      headers: {
        'content-type': 'application/json'
      },
      body: jsonEncode({'country_code': 'PL', 'store_key': 'PL1884'}));
    return jsonDecode(res.body);
  }

  Future<List<LidlPayCardModel>> getCards() async {
    var res = await get(PaymentsURL + 'cards/v1/PL');
    var body = jsonDecode(res.body);
    List<dynamic> cards = body['cards'];
    return cards.map((card) {
      return LidlPayCardModel.fromJson(card);
    }).toList();
  }

  Future<String> getQR(String cardId) async {
    var res = await post(PaymentsURL + 'cards/v1/PL/QR',
      headers: {
        'content-type': 'application/json'
      },
      body: jsonEncode({'loyaltyId': cardId}));
    if (res.statusCode == 401) {
      print('Token expired, retrying...');
      await cred.getTokenResponse(true);
      return getQR(cardId);
    }
    print("Got code from API:");
    print('Status code: ' + res.statusCode.toString());
    return jsonDecode(res.body)['paymentQR'];
  }
}
