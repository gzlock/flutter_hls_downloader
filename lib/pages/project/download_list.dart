import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'file_task.dart';

class DownloadList extends StatelessWidget {
  final Map<String, FileTask> tasks;
  final TaskStatus? status;

  const DownloadList({super.key, required this.tasks, this.status});

  @override
  Widget build(BuildContext context) {
    final _tasks = (status == null
            ? tasks.values
            : tasks.values.where((task) {
                if (status == TaskStatus.loading)
                  return task.status.value.isLoading;
                else if (status == TaskStatus.success)
                  return task.status.value.isSuccess;
                else if (status == TaskStatus.error)
                  return task.status.value.isError;
                else if (status == TaskStatus.wait)
                  return task.status.value.isEmpty;
                return false;
              }))
        .toList();
    return ListView.separated(
      itemCount: _tasks.length,
      separatorBuilder: (_, i) => Divider(),
      itemBuilder: (_, i) {
        final task = _tasks[i];
        return Obx(() => ListTile(
              title: Text('第 $i 个碎片'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: task.url,
                    child: Text(
                      '链接：${task.url}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  Tooltip(
                    message: task.filePath,
                    child: Text(
                      '存储：${task.filePath}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              trailing: _status(task.status.value),
            ));
      },
    );
  }

  static Widget? _status(RxStatus status) {
    if (status.isLoading) return Text('下载中');
    if (status.isSuccess) return Text('完成');
    if (status.isEmpty) return Text('排队');
    if (status.isError) {
      return Column(
        children: [
          Tooltip(
            message: status.errorMessage,
            child: Text('下载失败'),
          ),
          InkWell(
            child: Text('重试'),
            onTap: () {},
          ),
        ],
      );
    }
    return null;
  }
}
