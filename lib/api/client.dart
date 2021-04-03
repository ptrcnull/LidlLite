import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:lidl_lite/api/models/lidl_pay_card.dart';
import 'package:lidl_lite/util/device_id.dart';
import 'package:lidl_lite/util/openid.dart';

const AppGatewayURL = 'https://appgateway.lidlplus.com/';
const PaymentsURL = 'https://payments.lidlplus.com/';
const AppVersion = '14.34.7';
const ApiVersion = 'v23';

var api = ApiClient();

class ApiClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  Credential cred;

  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['authorization'] = 'Bearer ' + cred.token.accessToken ?? '';

    request.headers['app'] = 'com.lidl.eci.lidlplus';
    request.headers['app-version'] = AppVersion;
    request.headers['operating-system'] = 'Android';
    request.headers['countryv1model'] = 'PL';
    request.headers['deviceid'] = await getDeviceID();

    return _inner.send(request);
  }

  Future<bool> init() async {
    var res = await post(AppGatewayURL + 'app/$ApiVersion/PL/init?appVersion=$AppVersion');
    var body = jsonDecode(res.body);
    return body['code'] == 'RESULT_I40_01';
  }

  Future<Map<String, dynamic>> getProfile() async {
    var res = await post(AppGatewayURL + 'app/$ApiVersion/PL/contacts/lidlplusprofile',
      headers: {
        'content-type': 'application/json'
      },
      body: jsonEncode({'country_code': 'PL'}));
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
