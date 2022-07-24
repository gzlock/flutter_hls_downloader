import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dynamic_parallel_queue/dynamic_parallel_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hls_downloader/pages/project/processing_toast_widget.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/shell_run.dart';

import '../../main.dart';
import '../../project.dart';
import '../../utils.dart';
import 'file_task.dart';

class PageMergeMp4 extends StatelessWidget {
  PageMergeMp4({super.key, required this.project, required this.files});

  final Project project;
  final RxMap<String, FileTask> files;
  final hasFFmpeg = RxnBool();
  final _ffmpegVersion = RxString('');
  late final waterMark = project.waterMark;
  late final waterMarkText = project.waterMarkText.controller();
  late final waterMarkCount = project.waterMarkCount.controller();
  final enable = RxBool(true);
  final waterMarkCountUniqueKey = UniqueKey();
  final fileQueue = Queue(parallel: Platform.numberOfProcessors);

  Future<void> _check() async {
    hasFFmpeg.value = null;
    final list = await Future.wait(
        [ffmpegVersion(), Future.delayed(Duration(seconds: 1))]);

    final String? version = list.first;
    hasFFmpeg.value = version != null;
    _ffmpegVersion.value =
        version == null ? '没有安装FFmpeg，无法使用该功能' : '版本号：$version';
  }

  @override
  Widget build(BuildContext context) {
    _check();
    return Obx(() {
      Widget body;
      if (hasFFmpeg.value == null) {
        body = Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('正在检测FFmpeg'),
            ],
          ),
        );
      } else if (hasFFmpeg.value!) {
        body = createBody();
      } else {
        body = Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '检测不到FFmpeg',
                style: TextStyle(fontSize: 20),
              ),
              Text(
                '安装后请确保可以在Terminal中调用FFmpeg',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _check,
                child: Text('再次检测'),
              ),
            ],
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('合并为MP4文件'),
          actions: hasFFmpeg.value == true
              ? [
                  InkWell(
                    onTap: startMerge,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, right: 8),
                      child: Row(
                        children: [
                          Icon(Icons.call_merge),
                          SizedBox(width: 8),
                          Text('合并'),
                        ],
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        body: body,
      );
    });
  }

  Widget createBody() {
    print('build body');
    final items = [
      ListTile(
        title: Text('FFmpeg'),
        subtitle: Text(_ffmpegVersion.value),
      ),
      ListTile(
        title: Text('已有视频碎片'),
        trailing: Text(files.length.toString()),
      ),
      ListTile(
        title: Text('撤销添加水印操作'),
        subtitle: Text('即将视频碎片还原为没有添加文字水印前的文件'),
        onTap: _recoverFiles,
      ),
      CheckboxListTile(
        value: waterMark.value,
        onChanged: (val) {
          waterMark.set(val!);
        },
        title: Text('合并前给碎片添加文字水印'),
        subtitle: waterMark.value
            ? Column(
                children: [
                  Obx(() => TextField(
                        key: waterMarkCountUniqueKey,
                        enabled: enable.value,
                        keyboardType: TextInputType.number,
                        controller: waterMarkCount.controller,
                        focusNode: waterMarkCount.focusNode,
                        decoration: InputDecoration(labelText: '给多少碎片添加水印'),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      )),
                  TextField(
                    decoration: InputDecoration(labelText: '水印文字'),
                    controller: waterMarkText.controller,
                  ),
                ],
              )
            : null,
      )
    ];
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, i) => Divider(),
      itemBuilder: (_, i) => items[i],
    );
  }

  /// 开始合并文件
  Future<void> startMerge() async {
    if (files.isEmpty) return;

    await _copyFontToAppPath();
    await _createFileListTxt();
    ToastFuture toast;
    if (waterMark.value) {
      await _tsAddWaterMark();
    }
    try {
      final file = await _mergeToMp4();
      Get.dialog(
        AlertDialog(
          title: Text('合并完成'),
          content: Text('是否打开文件'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Get.back();
                String? command;
                if (GetPlatform.isWindows) {
                  command = 'explorer /select,"${file.absolute.path}"';
                } else if (GetPlatform.isMacOS && GetPlatform.isLinux) {
                  command = ['open', '-R', file.absolute.path].join(' ');
                }
                if (command == null) {
                  showToast('无法打开文件');
                  return;
                }
                run(command, verbose: false);
              },
              child: Text('打开文件'),
            )
          ],
        ),
      );
      print('合并成功');
    } catch (e) {
      print('合并失败');
    }
  }

  /// 创建ts文本列表，给ffmpeg合并用
  Future<void> _createFileListTxt() async {
    final txt = File(path.join(project.savePath.value, 'list.txt'));
    await txt.writeAsString(files.values.map<String>((f) {
      return 'file \'${f.filePath.toString()}\'';
    }).join('\n'));
  }

  /// 复制资源字体文件到app目录
  Future<void> _copyFontToAppPath() async {
    final fontFile = File(path.join(storePath, fontName));
    if (fontFile.existsSync()) return;
    print('copy font');
    final ByteData data = await rootBundle.load('fonts/$fontName');
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await fontFile.writeAsBytes(bytes);
  }

  /// 添加水印
  Future<void> _tsAddWaterMark() async {
    final font = path.join(storePath, fontName);
    final watermark = waterMarkText.value.value;
    final random = Random();
    final List<FileTask> list = List.from(files.values)..shuffle(random);
    final finalCount = list.length > waterMarkCount.value.value
        ? waterMarkCount.value.value
        : list.length;

    final info = await getVideoInfo(list.first.filePath);

    List.generate(finalCount, (index) {
      final file = list[index];
      print('添加水印 ${file.filePath}');
      final top = random.nextBool();
      final left = random.nextBool();
      String x = (random.nextInt(90) + 10).toString();
      String y = (random.nextInt(90) + 10).toString();
      if (!left) {
        x = 'W-text_w-$x';
      }
      if (!top) {
        y = 'H-text_h-$y';
      }

      fileQueue.add(() async {
        final oldFile = '${file.filePath}_';
        await File(file.filePath).rename(oldFile);
        final command = [
          'ffmpeg -i "$oldFile"',
          '-vf "drawtext=fontfile=\'$font\': text=\'$watermark\'',
          ':x=$x: y=$y: fontsize=20: fontcolor=white@0.8: box=1: boxcolor=random@0.5: boxborderw=5"',
          '-c:a copy -c:v ${info.codec_name} -profile:v ${info.profile} -level ${info.level}',
          '${file.filePath} -y',
        ].join(' ');
        // print(command);
        return run(command, verbose: false);
      });
    });
    final toast = ProcessingToastWidget.showQueue('添加文字水印', fileQueue);
    await fileQueue.whenComplete();
    toast.dismiss();
  }

  Future<File> _mergeToMp4() async {
    final now = DateTime.now();
    final target =
        path.join(project.savePath.value, '${fileNameFormat.format(now)}.mp4');
    final command = [
      'ffmpeg',
      '-f concat',
      '-safe 0',
      '-i "${path.join(project.savePath.value, 'list.txt')}"',
      '-c copy',
      '"$target" -y'
    ].join(' ');
    print('合并mp4 $command');
    final toast = ProcessingToastWidget.showText('正在合并为mp4文件');
    await Future.wait([
      Future.delayed(Duration(seconds: 1)),
      run(
        command,
        verbose: false,
      ),
    ]);
    toast.dismiss();
    return File(target);
  }

  /// 删除已添加文字水印的视频碎片
  /// 即恢复原状
  _recoverFiles() async {
    if (files.isEmpty) return;

    for (var file in files.values) {
      fileQueue.add(() async {
        final old = File(file.filePath + '_');
        if (await old.exists()) {
          await File(file.filePath).delete();
          await old.rename(file.filePath);
        }
      });
    }

    if (fileQueue.pending == 0) return;

    final toast = ProcessingToastWidget.showQueue('恢复中', fileQueue);
    await Future.wait([
      Future.delayed(Duration(seconds: 1)),
      fileQueue.whenComplete(),
    ]);
    toast.dismiss();
  }
}
