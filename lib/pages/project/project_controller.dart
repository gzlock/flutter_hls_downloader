import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;

import '../../utils/project.dart';
import '../../utils/utils.dart';
import 'file_task.dart';
import 'log.dart';

enum ProjectState {
  none, // 无状态
  working, // 工作中
}

class ProjectController extends GetxController {
  final Project project;

  /// 项目状态
  final Rx<ProjectState> _state = ProjectState.none.obs;

  /// 下载任务列表状态筛选器
  final Rxn<TaskState> _downloadListFilter = Rxn();

  /// 下载任务列表
  final RxMap<String, FileTask> tasks = RxMap();

  /// 日志
  final RxList<Log> logs = RxList();

  Dio? _http;

  ProjectController(this.project);

  bool get isWorking => _state.value == ProjectState.working;

  start() {
    log('任务开始', color: Colors.green);
    _http = createHttpFromProject(project);
    _state.value = ProjectState.working;
    parseHls(Uri.parse(project.hls.value), isFirst: true);
  }

  Future stop() {
    log('任务停止', color: Colors.red);
    _state.value = ProjectState.none;
    return project.queue.whenComplete();
  }

  TaskState? get downloadListFilter => _downloadListFilter.value;

  set downloadListFilter(TaskState? value) {
    _downloadListFilter.value = value;
  }

  Future<void> parseHls(
    Uri url, {
    HlsMasterPlaylist? masterPlaylist,
    required bool isFirst, // 是不是开始任务后的第一次获取hls
  }) async {
    HlsPlaylist? playlist;
    try {
      // debugPrint('parseHls $url');
      // debugPrint('${masterPlaylist == null ? '没有' : '有'}提供主体m3u8');
      final data = await _http!.getUri(url).then((res) => res.data);
      // debugPrint('m3u8 内容\n $data');
      playlist = await HlsPlaylistParser.create(masterPlaylist: masterPlaylist)
          .parseString(url, data);
    } catch (e) {
      showToast('出现错误');
      if (e is DioError) {
        log('读取Hls源出现网络错误：\n${e.message}', type: LogType.error);
      } else {
        log('未知错误：\n ${e.toString()}', type: LogType.error);
      }
      if (isFirst) stop();
    }
    if (playlist is HlsMasterPlaylist) {
      // master m3u8 file
      debugPrint('m3u8主体 变体(${playlist.variants.length})');
      log('识别到以下分辨率：');
      final List<Variant> variants = List.from(playlist.variants);
      variants.sort((a, b) => a.format.bitrate! - b.format.bitrate!);
      for (var v in variants) {
        Color? color;
        String download = '';
        if (v == variants.last) {
          color = Colors.green;
          download = '正在下载 ';
        }
        log(
          '$download分辨率 ${v.format.width} x ${v.format.height}, 码率 ${v.format.bitrate}',
          color: color,
        );
      }
      if (isWorking) {
        return parseHls(
          playlist.variants.last.url,
          masterPlaylist: playlist,
          isFirst: false,
        );
      }
    } else if (playlist is HlsMediaPlaylist) {
      // debugPrint('m3u8媒体');
      // media m3u8 file
      mediaM3u8(playlist);
      if (!playlist.hasEndTag && isWorking) {
        // debugPrint('直播型m3u8');
        await Future.delayed(Duration(seconds: 2));
        parseHls(
          url,
          masterPlaylist: masterPlaylist,
          isFirst: false,
        );
      } else if (isWorking) {
        stop();
      }
    }
  }

  void mediaM3u8(HlsMediaPlaylist variant) {
    for (var segment in variant.segments) {
      final url = segment.url;
      if (url == null) continue;
      if (tasks.containsKey(url)) continue;

      final uri = Uri.parse(url);
      late final String fileName, downloadUrl;
      if (uri.isAbsolute) {
        downloadUrl = url;
        fileName = uri.pathSegments.last;
      } else {
        downloadUrl = Uri.parse(variant.baseUri!).resolve(url).toString();
        fileName = Uri.parse(url).pathSegments.last;
      }

      final task = FileTask(
        _http!,
        downloadUrl,
        path.join(project.savePath.value, fileName),
      );
      tasks[segment.url!] = task;
      project.queue.add(() => task.download());
    }
  }

  void log(String text, {LogType type = LogType.normal, Color? color}) =>
      logs.insert(0, Log(text, DateTime.now(), type, color: color));
}
