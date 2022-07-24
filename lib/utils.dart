import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:intl/intl.dart';
import 'package:process_run/shell_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final String storePath;
late SharedPreferences prefs;
final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
final fileNameFormat = DateFormat('yyyyMMdd HH_mm_ss');

Dio createHttp({
  required String userAgent,
  int? errorRetry,
  String? proxy,
}) {
  // print('创建http');
  final http = Dio(BaseOptions(
    // connectTimeout: 10000,
    // receiveTimeout: 20000,
    followRedirects: true,
    headers: {'user-agent': userAgent},
  ));
  if (errorRetry != null && errorRetry > 0) {
    http.interceptors.add(RetryInterceptor(
      dio: http,
      logPrint: print, // specify log function (optional)
      retries: errorRetry, // retry count (
      // optional)
    ));
  }
  if (proxy != null && proxy.isNotEmpty) {
    (http.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      // config the http client
      client.findProxy = (uri) {
        return 'PROXY $proxy';
      };
      // you can also create a new HttpClient to dio
      // return HttpClient();
    };
  }
  return http;
}

Future<String?> ffmpegVersion() async {
  String? res;
  try {
    await run(
      'ffmpeg -version',
      verbose: false,
    ).then((value) => res = value.first.outText);
  } catch (e) {}

  /// ffmpeg version 5.0.1-essentials_build-www.gyan.dev Copyright (c) 2000-2022 the FFmpeg developers
  // print('res: $res');
  if (res == null) return null;
  return res!.split('\n').first.split(' ')[2];
}

const _str = '0123456789abcdefghijklmnopqrstwuvxyzABCDEFGHIJKLMNOPQRSTWUVXYZ';

String randomString([length = 5]) {
  return List.generate(
      length, (index) => _str[math.Random().nextInt(_str.length)]).join();
}

class VideoStreamInfo {
  final String codec_name;
  final String profile;
  final String level;

  VideoStreamInfo(this.codec_name, this.profile, this.level);

  factory VideoStreamInfo.fromJson(Map map) => VideoStreamInfo(
        map['codec_name'],
        map['profile'],
        map['level'].toString(),
      );
}

Future<VideoStreamInfo> getVideoInfo(String path) async {
  final res = await run(
    [
      'ffprobe',
      '-v quiet',
      '-select_streams v:0',
      '-print_format json',
      '-show_streams $path',
    ].join(' '),
    verbose: false,
  );
  return VideoStreamInfo.fromJson(jsonDecode(res.outText)['streams'].first);
}
