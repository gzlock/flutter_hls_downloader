import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'pages/main/page.dart';
import 'pages/project/page.dart';
import 'pages/project/page_merge_mp4.dart';
import 'pages/project/project_controller.dart';
import 'utils/project.dart';
import 'utils/utils.dart';

class ReloadProjectsWindowListener extends WindowListener {
  @override
  void onWindowFocus() {
    Projects.load();
  }
}

const isDev = !bool.fromEnvironment('dart.vm.product', defaultValue: false);

const fontName = 'SourceHanSansCN-Regular.otf';

late final List<String> arguments;

void main(List<String> _arguments) async {
  arguments = _arguments;
  debugPrint('启动参数 ${jsonEncode(arguments)}');
  storePath = (await getApplicationSupportDirectory()).path;
  debugPrint('持久化存储路径 $storePath');
  prefs = await SharedPreferences.getInstance();
  WidgetsFlutterBinding.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized();

  /// todo 显示版本号
  final packageInfo = await PackageInfo.fromPlatform();
  WindowOptions windowOptions = WindowOptions(
    title: 'HLS下载器 v${packageInfo.version}',
    size: Size(800, 600),
    minimumSize: Size(800, 600),
    center: true,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  windowManager.addListener(ReloadProjectsWindowListener());

  Projects.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
      textPadding: EdgeInsets.all(8),
      child: GetMaterialApp(
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'font',
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => MyHomePage()),
          GetPage(
            name: '/project/:id',
            page: () => PageProject(),
            binding: BindingsBuilder(() {
              Get.lazyPut<ProjectController>(() =>
                  ProjectController(Projects.projects[Get.parameters['id']]!));
            }),
          ),
          GetPage(name: '/mergeMp4/:id', page: () => PageMergeMp4()),
        ],
      ),
    );
  }
}
