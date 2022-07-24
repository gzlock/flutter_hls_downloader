import 'package:flutter/material.dart';
import 'package:flutter_hls_downloader/pages/project/file_task.dart';
import 'package:get/get.dart';

import '../../project.dart';

class DownLoadToolBar extends StatelessWidget {
  final Project project;
  final RxMap<String, FileTask> files;

  const DownLoadToolBar({
    Key? key,
    required this.project,
    required this.files,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          child: Text('清空', style: TextStyle(color: Colors.white)),
          onPressed: () => files.clear(),
        ),
        SizedBox(width: 10),
        TextButton(
          child: Text('合并', style: TextStyle(color: Colors.white)),
          onPressed: () => Get.toNamed(
            '/mergeMp4/${project.id}',
            arguments: files,
          ),
        ),
      ],
    );
  }
}
