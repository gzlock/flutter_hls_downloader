import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../utils/project.dart';

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
  final Project project;
  final Rx<RxStatus> state;
  final String url;
  final String filePath;
  int times = 0;

  FileTask(
    this.project,
    this.url,
    this.filePath, [
    RxStatus? state,
  ]) : state = Rx(state ?? RxStatus.empty());

  Future<FileTask> download() async {
    state.value = RxStatus.loading();
    times++;
    try {
      await project.http.download(url, filePath);
      if (Random().nextBool()) {
        throw DioError(
          requestOptions: RequestOptions(path: url),
        );
      }
      state.value = RxStatus.success();
    } catch (e) {
      if (times <= project.errorRetry.value) {
        return download();
      } else {
        if (e.runtimeType == DioError) {
          e as DioError;
          if (e.response == null) {
            state.value = RxStatus.error('网络错误： ${e.message}');
          } else {
            state.value = RxStatus.error('网络错误，状态码： ${e.response!.statusCode}');
          }
        } else {
          state.value = RxStatus.error('未知错误 ${e.toString()}');
        }
      }
    }
    return this;
  }
}
