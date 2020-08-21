import 'package:LidlLite/api/client.dart';
import 'package:http/http.dart' as http;

import 'package:openid_client/openid_client.dart' as openid;

class OpenIDHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.url.path.endsWith('/token')) {
      request.headers['authorization'] = 'Basic TGlkbFBsdXNOYXRpdmVDbGllbnQ6c2VjcmV0';
    }

    return _inner.send(request);
  }
}

class Credential extends openid.Credential {
  openid.TokenResponse get token => openid.TokenResponse.fromJson(super.response);

  Future<openid.TokenResponse> getTokenResponse([bool forceRefresh = false]) async {
    var res = await super.getTokenResponse(forceRefresh);

    api.token = res.accessToken;

    return res;
  }

  Credential.fromJson(Map<String, dynamic> json) : super.fromJson(json, httpClient: OpenIDHttpClient());
}

class OpenIDResolver {
  openid.Issuer issuer;
  openid.Client client;
  openid.Flow flow;

  Future<String> getURL() async {
    issuer = await openid.Issuer.discover(Uri.parse('https://accounts.lidl.com/'));

    client = openid.Client(issuer, "LidlPlusNativeClient", httpClient: OpenIDHttpClient());

    flow = openid.Flow.authorizationCodeWithPKCE(client);
    flow.redirectUri = Uri.parse('com.lidlplus.app://callback');

    return flow.authenticationUri.toString().replaceFirst(
        'openid',
        'openid%20profile%20offline_access%20lpprofile%20lpapis');
  }

  Future<openid.Credential> getCredential(String code) {
    return flow.callback({'code': code, 'state': flow.state});
  }
}
