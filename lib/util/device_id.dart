import 'package:device_info/device_info.dart';

Future<String> getDeviceID() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  var info = await deviceInfo.androidInfo;
  return info.androidId;
}
