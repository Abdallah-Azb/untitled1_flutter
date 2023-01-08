import 'package:dio/dio.dart';

/*
requestLiveInfo() async {
  String token =
      "Bearer 651c7944b33c8c49b61d77bed886c75e52e1656f70db56fa07de3ba1f40689b6";

  String liveInfoApi = "https://api.doorbird.io/live/info";

  try {
    Dio dio = Dio();
    dio.options.headers = {
      "accept": "application/json",
      "Authorization": token,
      "cloud-mjpg": "active"
    };
    var response = await dio.get(liveInfoApi);
    if (response.statusCode == 401) {
      responseDataRequest = "Yoy Aye Unauthorized";
    } else if (response.statusCode == 200) {
      // Run Camera Fun
      responseDataRequest = '';
      Map<String, dynamic> jsonData = json.decode(response.toString());
      sessionId = jsonData["video"]["cloud"]["mjpg"]["default"]["session"];
      keyEncepted = jsonData["video"]["cloud"]["mjpg"]["default"]["key"];
      print("keyEncepted keyEncepted keyEncepted  ==>   $keyEncepted");
    }
  } catch (e) {
    print(e);
    responseDataRequest = e.toString();
  }
  setState(() {});
}
*/
///
//
///
//
///
//
///