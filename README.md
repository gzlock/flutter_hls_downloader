# flutter_hls_downloader

用Flutter实现的HLS视频资源下载器

基于本人多年录制电视网络直播节目经验的开发而成

已经迭代了两个用python开发的录制软件
[MrPlayer_MainLand_Live_Server](https://github.com/gzlock/MrPlayer_MainLand_Live_Server)
[py_gui_hls_aria2](https://github.com/gzlock/py_gui_hls_aria2)

HLS直播内容分秒必争，一个直播视频碎片下载错误等待几分钟后可能就不能再下载了，已实现下载任务的快速超时、下载失败后立即重新下载、人手重新下载已标记为下载失败的视频碎片。

## ！不是所有的HLS资源都可以下载的！

有些hls源(在原网页用js解码)，连streamlink、各种浏览器视频下载器那些工具都无法下载，本工具也无能为力

## 截图

![截图](https://raw.githubusercontent.com/gzlock/images/master/flutter_hls_downloader/project_page.jpg)

## 用到的字体:

阿里巴巴普惠体

## License

APACHE LICENSE 2.0
