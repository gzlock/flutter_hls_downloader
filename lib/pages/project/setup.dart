import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../utils/project.dart';

class SettingWidget extends StatelessWidget {
  SettingWidget({
    super.key,
    required this.enable,
    required this.project,
  });

  final RxBool enable;
  final Project project;
  late final hls = project.hls.controller();
  late final proxy = project.proxy.controller();
  late final downloadParallel =
      project.downloadParallel.controller(beforeSave: (val) {
    if (val < 2) {
      val = 2;
    } else if (val > 10) {
      val = 10;
    }
    return val;
  });
  late final errorRetry = project.errorRetry.controller(beforeSave: (val) {
    if (val < 2) {
      val = 2;
    } else if (val > 10) {
      val = 10;
    }
    return val;
  });
  late final userAgent = project.userAgent.controller();

  @override
  Widget build(BuildContext context) {
    final items = [
      ListTile(
          title: Obx(() => TextField(
                controller: hls.controller,
                enabled: enable.value,
                decoration: InputDecoration(labelText: 'HLS源，支持Live及VOD'),
              ))),
      ListTile(
        title: Obx(() => TextField(
              controller: proxy.controller,
              enabled: enable.value,
              decoration: InputDecoration(
                labelText: '代理，例如 127.0.0.1:7890',
                prefixText: 'http://',
              ),
            )),
      ),
      ListTile(
          title: Obx(() => TextField(
                readOnly: true,
                controller: TextEditingController(text: project.savePath.value),
                decoration: InputDecoration(
                  labelText: '点击选择存储路径',
                  suffix: Row(mainAxisSize: MainAxisSize.min, children: [
                    Obx(() => TextButton.icon(
                          icon: Icon(Icons.create_new_folder),
                          label: Text('选择'),
                          onPressed: enable.value == true
                              ? () async {
                                  final path = await getDirectoryPath(
                                    initialDirectory: project.savePath.value,
                                    confirmButtonText: '选择',
                                  );
                                  print('选择了 $path');
                                  if (path != null) {
                                    project.savePath.set(path);
                                  }
                                }
                              : null,
                        )),
                    TextButton.icon(
                      icon: Icon(Icons.folder_open),
                      label: Text('打开'),
                      onPressed: () {
                        if (project.savePath.isBlank!) return;
                        if (Directory(project.savePath.value).existsSync()) {
                          launchUrlString('file://${project.savePath.value}');
                        } else {
                          showToast('存储目录不存在，无法打开');
                        }
                      },
                    ),
                  ]),
                ),
              ))),
      ListTile(
        title: Text('视频碎片同时下载数量'),
        subtitle: Text('最少2，最多10'),
        trailing: SizedBox(
          width: 40,
          child: Obx(() => TextField(
                enabled: enable.value,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: downloadParallel.controller,
                focusNode: downloadParallel.focusNode,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
        ),
      ),
      ListTile(
        title: Text('下载失败重试次数'),
        subtitle: Text('最少2，最多10'),
        trailing: SizedBox(
          width: 40,
          child: Obx(() => TextField(
                enabled: enable.value,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: errorRetry.controller,
                focusNode: errorRetry.focusNode,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              )),
        ),
      ),
      ListTile(
        title: Text('网络请求User-Agent'),
        subtitle: Obx(() => TextField(
              enabled: enable.value,
              decoration: InputDecoration(labelText: 'User-Agent'),
              controller: userAgent.controller,
            )),
      ),
      Obx(
        () => ListTile(
          title: Text('清空所有设置'),
          subtitle: Text('即恢复默认设置'),
          onTap: enable.value
              ? () async {
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
                  print('reset $sure');
                  if (sure != true) return;
                  project.reset();
                }
              : null,
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
