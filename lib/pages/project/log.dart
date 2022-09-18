import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/utils.dart';
import 'project_controller.dart';

enum LogType {
  normal,
  error,
}

class Log {
  final LogType type;
  final String text;
  final DateTime time;
  final Color? color;

  Log(this.text, this.time, this.type, {this.color});

  Widget toRow() {
    return DefaultTextStyle(
      style: TextStyle(
        color: color ?? (type == LogType.normal ? Colors.black : Colors.red),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: SelectableText(dateFormat.format(time))),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}

class LogListWidget extends GetWidget<ProjectController> {
  @override
  Widget build(BuildContext context) {
    final logs = controller.logs;
    return Obx(() => logs.isEmpty
        ? Center(child: Text('暂无日志'))
        : ListView.separated(
            padding: EdgeInsets.only(left: 16, right: 16),
            reverse: true,
            itemCount: logs.length,
            separatorBuilder: (_, i) => Divider(),
            itemBuilder: (_, i) => logs[i].toRow(),
          ));
  }
}

class LogActions extends GetWidget<ProjectController> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MaterialButton(
          child: Text('清空', style: TextStyle(color: Colors.white)),
          onPressed: () => controller.logs.clear(),
        ),
      ],
    );
  }
}
