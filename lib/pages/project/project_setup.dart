import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'list_tile_int.dart';
import 'project_controller.dart';

class SettingWidget extends GetWidget<ProjectController> {
  late final hls = controller.project.hls.controller();
  late final proxy = controller.project.proxy.controller();
  late final userAgent = controller.project.userAgent.controller();

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
          title: Obx(() => TextField(
                controller: hls.controller,
                enabled: !controller.isWorking,
                decoration: InputDecoration(labelText: 'HLS源，支持Live及VOD'),
              ))),
      ListTile(
        title: Obx(() => TextField(
              controller: proxy.controller,
              enabled: !controller.isWorking,
              decoration: InputDecoration(
                labelText: '代理，例如 127.0.0.1:7890',
                prefixText: 'http://',
              ),
            )),
      ),
      ListTile(
          title: Obx(() => TextField(
                readOnly: true,
                controller: TextEditingController(
                    text: controller.project.savePath.value),
                decoration: InputDecoration(
                  labelText: '点击选择存储路径',
                  suffix: Row(mainAxisSize: MainAxisSize.min, children: [
                    Obx(() => TextButton.icon(
                          icon: Icon(Icons.create_new_folder),
                          label: Text('选择'),
                          onPressed: controller.isWorking
                              ? null
                              : () async {
                                  final path = await getDirectoryPath(
                                    initialDirectory:
                                        controller.project.savePath.value,
                                    confirmButtonText: '选择',
                                  );
                                  debugPrint('选择了 $path');
                                  if (path != null) {
                                    controller.project.savePath.set(path);
                                  }
                                },
                        )),
                    TextButton.icon(
                      icon: Icon(Icons.folder_open),
                      label: Text('打开'),
                      onPressed: () async {
                        if (controller.project.savePath.isBlank!) return;
                        final dir =
                            Directory(controller.project.savePath.value);
                        final exists = await dir.exists();
                        if (exists) {
                          launchUrlString(
                              'file://${controller.project.savePath.value}');
                        } else {
                          showToast('存储目录不存在，无法打开');
                        }
                      },
                    ),
                  ]),
                ),
              ))),
      ListTileInt(
        title: Text('每次下载多少个视频碎片(队列)'),
        subtitle: Text('最少2，最多50'),
        value: controller.project.downloadParallel.value,
        step: 1,
        verify: (val) => val.clamp(2, 50),
        onChange: controller.project.downloadParallel.set,
      ),
      ListTileInt(
        title: Text('下载失败重试次数'),
        subtitle: Text('最少2，最多50'),
        value: controller.project.errorRetry.value,
        verify: (val) => val.clamp(2, 50),
        onChange: controller.project.errorRetry.set,
      ),
      ListTile(
        title: Text('网络请求User-Agent'),
        subtitle: Obx(() => TextField(
              enabled: !controller.isWorking,
              decoration: InputDecoration(labelText: 'User-Agent'),
              controller: userAgent.controller,
            )),
      ),
      Obx(
        () => ListTile(
          title: Text('清空所有设置'),
          subtitle: Text('即恢复默认设置'),
          onTap: controller.isWorking
              ? null
              : () async {
                  final sure = await Get.dialog<bool>(AlertDialog(
                    title: Text('请确定'),
                    content: Text('将会丢失所有已设置的值'),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        child: Text('确定'),
                      ),
                    ],
                  ));
                  debugPrint('reset $sure');
                  if (sure != true) return;
                  controller.project.reset();
                },
        ),
      ),
    ];
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, i) => Divider(),
      itemBuilder: (_, i) => items[i],
    );
  }
}
