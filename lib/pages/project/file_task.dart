import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum TaskState {
  wait,
  loading,
  success,
  error,
}

String taskStateToText(TaskState? status) {
  switch (status) {
    case TaskState.wait:
      return '排队';
    case TaskState.error:
      return '出错';
    case TaskState.success:
      return '完成';
    case TaskState.loading:
      return '下载中';
    default:
      return '全部';
  }
}

class FileTask {
  final Dio http;
  final Rx<RxStatus> state;
  final String url;
  final String filePath;

  FileTask(
    this.http,
    this.url,
    this.filePath, [
    RxStatus? state,
  ]) : state = Rx(state ?? RxStatus.empty());

  Future<FileTask> download() async {
    state.value = RxStatus.loading();
    await http.download(url, filePath).then((value) {
      state.value = RxStatus.success();
    }).catchError((err) {
      debugPrint('下载失败 $url');
      state.value = RxStatus.error(err.toString());
    });
    return this;
  }
}
