import 'dart:convert';
import 'package:dio/dio.dart';

class NetworkHelper {
  Dio dio = Dio();

// INJECT DIO
  NetworkHelper() {
    dio.options = BaseOptions(
      validateStatus: (_) => true,
    );
    dio.options.headers = {"accept": "application/json", "Authorization": token, "cloud-mjpg": "active"};
  }

  // ACCESS TOKEN
  final String token = "Bearer 2d919912d96006e786b1811675ee945faa7959c1f94cb36499b1d8d461bb8790";

  // END POINT LIVE
  final String liveInfoApi = "https://api.doorbird.io/live/info";

  // variable
  String? host;
  int? port;
  String? sessionId;
  String? key;

  //
  Future<ResponseGetInfo?> getInfo() async {
    ResponseGetInfo? responseGetInfo;
    try {
      final response = await dio.get(liveInfoApi);
      print("statusCode ==> ${response.statusCode}");
      // SUCCESS API
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonData = json.decode(response.toString());
        Map<String, dynamic> mjpgInfo = jsonData["video"]["cloud"]["mjpg"]["default"];
        host = mjpgInfo["host"];
        port = mjpgInfo["port"];
        sessionId = mjpgInfo["session"];
        key = mjpgInfo["key"];
        Map<String, String> dataMap = {
          "host": host.toString(),
          "port": port.toString(),
          "sessionId": sessionId.toString(),
          "key": key.toString(),
        };
        responseGetInfo = ResponseGetInfo(
            host: host.toString(),
            port: port.toString(),
            sessionId: sessionId.toString(),
            key: key.toString());
        print(dataMap);
      }

      /// Unauthorized
      /// YOU Need To New ACCESS Token
      else if (response.statusCode == 401) {
        print("Yoy Aye Unauthorized \n You Need To New Access Token");
      } else {
        print("Some Thing Want Wrong");
      }
    } catch (exception) {
      //   log(exception.toString(), error: 'ERROR GET INFO API', name: 'EXCEPTION API');
    }
    return responseGetInfo ;
  }
}

class ResponseGetInfo {
  final String host;
  final String port;
  final String sessionId;
  final String key;

  ResponseGetInfo({
    required this.host,
    required this.port,
    required this.sessionId,
    required this.key,
  });
}
