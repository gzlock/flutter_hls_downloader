import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;

import '../../project.dart';
import '../../utils.dart';
import 'download.dart';
import 'file_task.dart';
import 'log.dart';
import 'setup.dart';
import 'tab.dart';

class PageProject extends StatelessWidget {
  PageProject({super.key, required this.project});

  final Project project;

  /// 开始下载状态
  final Rx<RxStatus> status = RxStatus.empty().obs;

  /// 日志
  final RxList<Log> logs = RxList();

  /// 直播式HLS的循环下载
  Timer? looper;

  late final _tabController = Get.put(ProjectTabController([
    Tab(text: '设置'),
    Tab(child: Obx(() => Text('日志[${logs.length}]'))),
    Tab(child: Obx(() => Text('下载列表[${tasks.length}]'))),
  ]));
  late final hls = project.hls.controller();
  late final proxy = project.proxy.controller();
  late final savePath = project.savePath.controller();
  late final http = createHttp(
    userAgent: project.userAgent.value,
    errorRetry: project.errorRetry.value,
    proxy: project.proxy.value,
  );
  final RxBool enable = RxBool(true);

  final RxMap<String, FileTask> tasks = RxMap();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('项目 ${project.name}'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(kTextTabBarHeight),
          child: Row(
            children: [
              TabBar(
                isScrollable: true,
                controller: _tabController.controller,
                tabs: _tabController.tabs,
              ),
              Expanded(child: SizedBox()),
              Obx(() {
                switch (_tabController.index.value) {
                  case 0:
                    return SizedBox();
                  case 1:
                    return LogToolBar(logs: logs);
                  default:
                    return DownLoadToolBar(
                      project: project,
                      files: tasks,
                    );
                }
              })
            ],
          ),
        ),
        actions: [startButton()],
      ),
      body: TabBarView(
        controller: _tabController.controller,
        children: [
          SettingWidget(
            project: project,
            enable: enable,
          ),
          LogListWidget(logs: logs),
          TaskListWidget(tasks: tasks),
        ],
      ),
    );
  }

  void log(String text, [LogType type = LogType.normal]) =>
      logs.insert(0, Log(text, DateTime.now(), type));

  Widget startButton() {
    return Obx(() {
      var onTap, child;
      if (status.value.isEmpty) {
        onTap = startTask;
        child = Row(
          children: [
            Icon(
              Icons.play_circle_outline,
            ),
            SizedBox(width: 8),
            Text(
              '开始',
              style: TextStyle(),
            ),
          ],
        );
      } else {
        onTap = stopTask;
        child = Row(
          children: [
            Icon(
              Icons.stop_circle_outlined,
            ),
            SizedBox(width: 8),
            Text(
              '停止',
              style: TextStyle(),
            ),
          ],
        );
      }
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(left: 8, right: 8),
          child: child,
        ),
      );
    });
  }

  void startTask() {
    if (!status.value.isEmpty) return;
    if (project.hls.isBlank != false) {
      showToast('请填写Hls来源');
      return log('请填写Hls来源', LogType.error);
    }
    if (project.savePath.isBlank != false) {
      showToast('请选择保存路径');
      return log('请选择保存路径', LogType.error);
    } else {
      final dir = Directory(project.savePath.value);
      if (!dir.existsSync()) {
        showToast('存储目录不存在');
        return log('存储目录不存在', LogType.error);
      }
    }
    status.value = RxStatus.loading();
    enable.value = false;
    parseHls(Uri.parse(project.hls.value)).catchError((e) {
      enable.value = true;
      status.value = RxStatus.empty();
    });
  }

  void stopTask() {
    looper?.cancel();
    looper = null;
    project.queue.clear();
    status.value = RxStatus.empty();
  }

  Future<void> parseHls(Uri url, [HlsMasterPlaylist? masterPlaylist]) async {
    HlsPlaylist playlist;
    try {
      print('parseHls $url\n'
          '${masterPlaylist == null ? '没有' : '有'}提供主体m3u8');
      final data = await http.getUri(url).then((res) => res.data);
      // print('m3u8 内容\n $data');
      playlist = await HlsPlaylistParser.create(masterPlaylist: masterPlaylist)
          .parseString(url, data);
    } catch (e) {
      if (e is DioError) {
        log('Hls源返回网络错误：\n' + e.message, LogType.error);
      } else {
        log('未知错误：\n' + e.toString(), LogType.error);
      }
      status.value = RxStatus.empty();
      rethrow;
    }
    if (playlist is HlsMasterPlaylist) {
      // master m3u8 file
      print('m3u8主体 变体(${playlist.variants.length})');
      playlist.variants
        ..sort((a, b) => b.format.bitrate! - a.format.bitrate!)
        ..forEach((v) {
          log('variants 分辨率 ${v.format.width} x ${v.format.height}, 码率 ${v.format.bitrate}\n${v.url}');
        });
      if (status.value.isLoading) {
        return parseHls(playlist.variants.first.url, playlist);
      }
    } else if (playlist is HlsMediaPlaylist) {
      print('m3u8媒体');
      if (!playlist.hasEndTag && looper == null) {
        print('直播型m3u8，创建循环读取');
        looper?.cancel();
        looper = Timer.periodic(Duration(seconds: 2), (timer) {
          parseHls(url, masterPlaylist);
        });
      }
      // media m3u8 file
      mediaM3u8(playlist);
    }
  }

  void mediaM3u8(HlsMediaPlaylist variant) {
    variant.segments.forEach((segment) {
      final url = segment.url;
      if (url == null) return;
      if (tasks.containsKey(url)) return;

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
        downloadUrl,
        path.join(project.savePath.value, fileName),
      );
      tasks[segment.url!] = task;
      project.queue.add(() => task.download(http));
    });
  }
}
