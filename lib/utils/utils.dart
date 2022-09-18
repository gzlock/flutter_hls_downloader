import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:process_run/shell_run.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'project.dart';

const defaultUserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/103.0.5060.114 '
    'Safari/537.36 '
    'Edg/103.0.1264.49';

late final String storePath;
late SharedPreferences prefs;
final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
final fileNameFormat = DateFormat('yyyyMMdd HH_mm_ss');

Dio createHttpFromProject(Project project) => createHttp(
      userAgent: project.userAgent.value,
      errorRetry: project.errorRetry.value,
      proxy: project.proxy.value,
    );

Dio createHttp({
  required String userAgent,
  int? errorRetry,
  String? proxy,
}) {
  // debugPrint('创建http');
  final http = Dio(BaseOptions(
    connectTimeout: 5000,
    receiveTimeout: 10000,
    followRedirects: true,
    headers: {'user-agent': userAgent},
  ));
  if (errorRetry != null && errorRetry > 0) {
    http.interceptors.add(RetryInterceptor(
      dio: http,
      logPrint: debugPrint, // specify log function (optional)
      retries: errorRetry,
      retryDelays: [], // retry count (
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
  // debugPrint('res: $res');
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
