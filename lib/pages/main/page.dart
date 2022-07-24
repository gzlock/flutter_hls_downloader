import 'package:dynamic_parallel_queue/dynamic_parallel_queue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hls_downloader/pages/project/processing_toast_widget.dart';
import 'package:flutter_hls_downloader/utils.dart';
import 'package:get/get.dart';
import 'package:oktoast/oktoast.dart';
import 'package:process_run/shell_run.dart';

import '../../project.dart';
import '../../test.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _createProject(String name) {
    final project = Project(
      id: randomString(),
      name: name,
      data: {},
    );
    Projects.projects[project.id] = project;
    Projects.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          // parseHls(4);
          // hlsAudio('https://bitmovin-a.akamaihd.net/content/sintel/hls/playlist.m3u8');
        },
        child: Text('测试'),
      ),
      body: Obx(
        () => GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: Projects.projects.length + 1,
          itemBuilder: (_, i) {
            if (i < Projects.projects.length) {
              final project =
                  Projects.projects[Projects.projects.keys.elementAt(i)]!;
              return ListTile(
                tileColor: Colors.blue,
                onTap: () => Get.toNamed('/project/${project.id}'),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('项目'),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Icon(Icons.clear, color: Colors.deepOrange),
                      onPressed: () async {
                        final res = await Get.dialog(AlertDialog(
                          title: Text('确认删除 ${project.name} ?'),
                          actions: [
                            TextButton(
                                onPressed: () => Get.back(), child: Text('取消')),
                            ElevatedButton(
                              onPressed: () => Get.back(result: true),
                              child: Text('删除'),
                            ),
                          ],
                        ));
                        if (res != true) return;
                        Projects.projects.remove(project.id);
                        Projects.save();
                      },
                    ),
                  ],
                ),
                subtitle: Text(project.name),
                contentPadding: EdgeInsets.only(left: 6, right: 6),
              );
            }
            return ListTile(
              tileColor: Colors.green,
              onTap: () async {
                String? name;
                await Get.dialog(
                  AlertDialog(
                    title: Text('创建项目'),
                    content: TextField(
                      decoration: InputDecoration(labelText: '输入项目名称'),
                      onChanged: (val) => name = val,
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Get.back(),
                        child: Text('创建'),
                      ),
                    ],
                  ),
                );
                print('name $name');
                name = name?.trim();
                if (name == null || name!.isEmpty) return;
                _createProject(name!);
              },
              title: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.add), Text('创建项目')],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
