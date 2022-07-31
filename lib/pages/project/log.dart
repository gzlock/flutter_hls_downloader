import 'package:flutter/material.dart';
import 'package:flutter_hls_downloader/utils/utils.dart';
import 'package:get/get.dart';

enum LogType {
  normal,
  error,
}

class Log {
  final LogType type;
  final String text;
  final DateTime time;

  Log(this.text, this.time, this.type);

  Widget toRow() {
    return DefaultTextStyle(
      style:
          TextStyle(color: type == LogType.normal ? Colors.black : Colors.red),
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

class LogListWidget extends StatelessWidget {
  final RxList<Log> logs;

  const LogListWidget({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
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

class LogToolBar extends StatelessWidget {
  final RxList<Log> logs;

  const LogToolBar({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MaterialButton(
          child: Text('清空', style: TextStyle(color: Colors.white)),
          onPressed: () => logs.clear(),
        ),
      ],
    );
  }
}
