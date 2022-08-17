import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../utils/project.dart';

void settingDialog(Project project) async {
  String name = project.name.value;
  final sure = await Get.dialog(
    AlertDialog(
      title: Text('项目设置'),
      content: TextField(
        decoration: InputDecoration(labelText: '项目名称'),
        controller: TextEditingController(text: name),
        onChanged: (val) => name = val,
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('取消')),
        ElevatedButton(
          onPressed: () {
            if (name.isNotEmpty != true) {
              showToast('项目名称不能为空');
              return;
            }
            Get.back(result: true);
          },
          child: Text('修改'),
        ),
      ],
    ),
  );
  if (sure == true && name.isNotEmpty == true && project.name.value != name) {
    project.name.value = name;
    Projects.save();
  }
}
