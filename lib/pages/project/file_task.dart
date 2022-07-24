import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum TaskStatus {
  wait,
  loading,
  success,
  error,
}

class FileTask {
  final Rx<RxStatus> status;
  final String url;
  final String filePath;

  FileTask(this.url, this.filePath, [RxStatus? status])
      : status = Rx(status ?? RxStatus.empty());

  Future<FileTask> download(Dio http) async {
    status.value = RxStatus.loading();
    await http.download(url, filePath);
    status.value = RxStatus.success();
    return this;
  }
}

class TaskListWidget extends StatelessWidget {
  final Map<String, FileTask> tasks;
  final TaskStatus? status;

  const TaskListWidget({super.key, required this.tasks, this.status});

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
                  Text(
                    '链接：${task.url}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    '存储：${task.filePath}',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: SizedBox(
                width: 140,
                child: Text(_status(task.status.value)),
              ),
            ));
      },
    );
  }

  static String _status(RxStatus status) {
    if (status.isLoading) return '下载中';
    if (status.isSuccess) return '完成';
    if (status.isEmpty) return '等待';
    if (status.isError) return status.errorMessage ?? '错误';
    return '';
  }
}
