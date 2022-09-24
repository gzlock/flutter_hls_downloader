import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';

import 'file_task.dart';
import 'project_controller.dart';

class DownLoadListActions extends GetWidget<ProjectController> {
  final void Function() clear;

  DownLoadListActions(this.clear);

  final values = [null, ...TaskState.values];
  late final List<DropdownMenuItem<TaskState?>> items = values
      .map((value) => DropdownMenuItem(
            value: value,
            child: Text(taskStateToText(value)),
          ))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MaterialButton(
          textColor: Colors.white,
          onPressed: clear,
          child: Text('清空'),
        ),
        SizedBox(width: 10),
        MaterialButton(
          textColor: Colors.white,
          child: Text('合并'),
          onPressed: () {
            if (controller.isWorking) {
              showToast('正在录制，无法合并');
              return;
            }
            Get.toNamed(
              '/mergeMp4/${controller.project.id}',
              arguments: controller.tasks,
            );
          },
        ),
        Obx(
          () => DropdownButtonHideUnderline(
            child: DropdownButton<TaskState?>(
              value: controller.downloadListFilter,
              hint: Text(
                '状态',
                style: Theme.of(context).textTheme.button?.copyWith(
                      color: Colors.white,
                    ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.white, // <-- SEE HERE
              ),
              selectedItemBuilder: (_) {
                return values.map((value) {
                  String text = value == null ? '全部' : taskStateToText(value);
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        text,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  );
                }).toList();
              },
              items: items,
              onChanged: (val) {
                controller.downloadListFilter = val;
              },
            ),
          ),
        ),
      ],
    );
  }
}
