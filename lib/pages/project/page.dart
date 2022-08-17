import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;

import '../../utils/before_close.dart';
import '../../utils/project.dart';
import '../../utils/utils.dart';
import 'download_list.dart';
import 'download_tool_bar.dart';
import 'file_task.dart';
import 'log.dart';
import 'setting_dialog.dart';
import 'setup.dart';
import 'tab_controller.dart';

class PageProject extends StatelessWidget {
  PageProject({super.key, required this.project});

  final Project project;

  /// 开始下载状态
  final Rx<RxStatus> status = RxStatus.empty().obs;

  /// 日志
  final RxList<Log> logs = RxList();

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
  final RxBool enable = RxBool(true)
    ..listen((val) {
      BeforeClose.instance.intercept.value = !val;
    });

  final RxMap<String, FileTask> tasks = RxMap();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text('项目 ${project.name}')),
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
                      return startButton();
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
          actions: [
            MaterialButton(
              textColor: Colors.white,
              onPressed: () => settingDialog(project),
              child: Icon(Icons.settings),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController.controller,
          children: [
            SettingWidget(
              project: project,
              enable: enable,
            ),
            LogListWidget(logs: logs),
            DownloadList(tasks: tasks),
          ],
        ),
      ),
      onWillPop: () async {
        if (enable.value) return true;
        final sure = await Get.dialog(AlertDialog(
          title: Text('正在录制，确认退出录制工作？'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: Text('取消')),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: Text('确定'),
            ),
          ],
        ));
        if (sure != true) return false;
        stopTask();
        return true;
      },
    );
  }

  void log(String text, [LogType type = LogType.normal]) =>
      logs.insert(0, Log(text, DateTime.now(), type));

  Widget startButton() {
    return Row(
      children: [
        Obx(() {
          var onTap, child;
          if (status.value.isEmpty) {
            onTap = startTask;
            child = Row(
              children: [
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text('开始'),
              ],
            );
          } else {
            onTap = stopTask;
            child = Row(
              children: [
                Icon(
                  Icons.stop_circle_outlined,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text('停止'),
              ],
            );
          }
          return MaterialButton(
            onPressed: onTap,
            child: child,
            textColor: Colors.white,
          );
        }),
      ],
    );
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
    status.value = RxStatus.empty();
    clearDownloadQueue();
  }

  void clearDownloadQueue() async {
    final sure = await Get.dialog(AlertDialog(
      title: Text('是否清空视频碎片下载队列？'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('否')),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          child: Text('是'),
        ),
      ],
    ));
    if (sure != true) return;
    project.queue.clear();
  }

  Future<void> parseHls(Uri url, [HlsMasterPlaylist? masterPlaylist]) async {
    HlsPlaylist playlist;
    try {
      debugPrint('parseHls $url');
      debugPrint('${masterPlaylist == null ? '没有' : '有'}提供主体m3u8');
      final data = await http.getUri(url).then((res) => res.data);
      // debugPrint('m3u8 内容\n $data');
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
      debugPrint('m3u8主体 变体(${playlist.variants.length})');
      playlist.variants
        ..sort((a, b) => b.format.bitrate! - a.format.bitrate!)
        ..forEach((v) {
          log('variants 分辨率 ${v.format.width} x ${v.format.height}, 码率 ${v.format.bitrate}\n${v.url}');
        });
      if (status.value.isLoading) {
        return parseHls(playlist.variants.first.url, playlist);
      }
    } else if (playlist is HlsMediaPlaylist) {
      // debugPrint('m3u8媒体');
      // media m3u8 file
      mediaM3u8(playlist);
      if (!playlist.hasEndTag && status.value.isLoading) {
        debugPrint('直播型m3u8');
        await Future.delayed(Duration(seconds: 2));
        parseHls(url, masterPlaylist);
      } else if (status.value.isLoading) {
        stopTask();
        showToast('任务已完成');
      }
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
