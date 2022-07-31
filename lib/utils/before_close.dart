import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

class BeforeClose extends WindowListener {
  BeforeClose._constructor() {
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  /// 是否拦截关闭窗口
  final RxBool intercept = true.obs;
  static final instance = BeforeClose._constructor();

  @override
  void onWindowClose() async {
    super.onWindowClose();
    if (intercept.value) {
      final sure = await Get.dialog(AlertDialog(
        title: Text('工作中，确认退出程序？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('取消')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: Text('确定'),
          ),
        ],
      ));
      if (sure != true) return;
    }
    windowManager.destroy();
  }
}
