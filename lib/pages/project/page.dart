import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../utils/project.dart';
import 'download_list.dart';
import 'download_list_actions.dart';
import 'drawer.dart';
import 'log.dart';
import 'project_controller.dart';
import 'setup.dart';
import 'tab_controller.dart';

class PageProject extends GetWidget<ProjectController> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final _tabController = Get.put(ProjectTabController([
    Tab(text: '设置'),
    Tab(child: Obx(() => Text('日志[${controller.logs.length}]'))),
    Tab(child: Obx(() => Text('下载列表[${controller.tasks.length}]'))),
  ]));

  @override
  Widget build(BuildContext context) {
    final project = Projects.projects[Get.parameters['id']];
    if (project == null) {
      showToast('不存在的项目');
      Get.back();
      return SizedBox.shrink();
    }
    Get.create(() => ProjectController(project));
    return GetBuilder<ProjectController>(builder: (project) {
      return WillPopScope(
        onWillPop: () async {
          if (!controller.isWorking) return true;
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
        child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Obx(() => Text('项目 ${project.project.name}')),
            actions: [
              MaterialButton(
                textColor: Colors.white,
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                child: Icon(Icons.settings),
              ),
            ],
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
                        return LogActions();
                      default:
                        return DownLoadListActions(clearDownloadQueue);
                    }
                  })
                ],
              ),
            ),
          ),
          endDrawer: ProjectDrawer(),
          body: TabBarView(
            controller: _tabController.controller,
            children: [
              SettingWidget(),
              LogListWidget(),
              DownloadList(),
            ],
          ),
        ),
      );
    });
  }

  Widget startButton() {
    return Row(
      children: [
        Obx(() {
          void Function() onTap;
          Widget child;
          if (controller.isWorking) {
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
          } else {
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
          }
          return MaterialButton(
            onPressed: onTap,
            textColor: Colors.white,
            child: child,
          );
        }),
      ],
    );
  }

  void startTask() {
    print('startProject ${controller.isWorking}');
    if (controller.isWorking) return;
    if (controller.project.hls.isBlank != false) {
      showToast('请填写Hls源');
      return controller.log('请填写Hls源', type: LogType.error);
    }
    if (controller.project.savePath.isBlank != false) {
      showToast('请选择保存路径');
      return controller.log('请选择保存路径', type: LogType.error);
    } else {
      final dir = Directory(controller.project.savePath.value);
      if (!dir.existsSync()) {
        showToast('存储目录不存在');
        return controller.log('存储目录不存在', type: LogType.error);
      }
    }
    controller.start();
  }

  void stopTask() {
    showToast('任务已完成');
    controller.stop();
    clearDownloadQueue();
  }

  void clearDownloadQueue() async {
    if (controller.project.queue.pending == 0) return;
    final sure = await Get.dialog(AlertDialog(
      title: Text('是否停止所有下载任务？'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('否')),
        ElevatedButton(
          onPressed: () => Get.back(result: true),
          child: Text('是'),
        ),
      ],
    ));
    if (sure != true) return;
    controller.tasks.clear();
    controller.project.queue.clear();
  }
}
