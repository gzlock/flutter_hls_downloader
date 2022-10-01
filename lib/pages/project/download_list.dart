import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'file_task.dart';
import 'project_controller.dart';

class DownloadList extends GetWidget<ProjectController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final state = controller.downloadListFilter;
        final tasks = controller.tasks;
        final List<FileTask> _tasks = List.from(state == null
                ? tasks.values
                : tasks.values.where((task) {
                    if (state == TaskState.loading) {
                      return task.state.value.isLoading;
                    } else if (state == TaskState.success) {
                      return task.state.value.isSuccess;
                    } else if (state == TaskState.error) {
                      return task.state.value.isError;
                    } else if (state == TaskState.wait) {
                      return task.state.value.isEmpty;
                    }
                    return false;
                  }))
            .reversed
            .cast<FileTask>()
            .toList();
        return ListView.separated(
          itemCount: _tasks.length,
          reverse: true,
          separatorBuilder: (_, i) => Divider(),
          itemBuilder: (_, i) {
            final task = _tasks[i];
            return Obx(() => ListTile(
                  title: Text('第 ${_tasks.length - i} 个碎片'),
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
                  trailing: _status(task),
                ));
          },
        );
      },
    );
  }

  Widget? _status(FileTask file) {
    final state = file.state.value;
    if (state.isLoading) return Text('第${file.times}次 下载中');
    if (state.isSuccess) return Text('完成');
    if (state.isEmpty) return Text('排队');
    if (state.isError) {
      return Column(
        children: [
          Tooltip(
            message: state.errorMessage,
            child: Text(
              '下载失败',
              style: TextStyle(color: Colors.red),
            ),
          ),
          MaterialButton(
            child: Text('重试'),
            onPressed: () {
              file.download();
            },
          ),
        ],
      );
    }
    return null;
  }
}
