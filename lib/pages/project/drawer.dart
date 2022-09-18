import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import '../../utils/project.dart';
import 'project_controller.dart';

class ProjectDrawer extends GetView<ProjectController> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView(
      padding: EdgeInsets.all(8),
      children: [
        TextField(
          decoration: InputDecoration(labelText: '项目名称'),
          controller:
              TextEditingController(text: controller.project.name.value),
          onChanged: (val) {
            if (val.isEmpty) {
              showToast('名称不能为空');
              return;
            }
            controller.project.name.value = val;
            Projects.save();
          },
        ),
      ],
    ));
  }
}