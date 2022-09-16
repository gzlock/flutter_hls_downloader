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
    await http.download(url, filePath).then((value) {
      status.value = RxStatus.success();
    }).catchError((err) {
      debugPrint('下载失败 $url');
      status.value = RxStatus.error(err.toString());
    });
    return this;
  }
}
