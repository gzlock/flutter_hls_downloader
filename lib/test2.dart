import 'package:flutter/material.dart';
import 'package:flutter_hls_parser/flutter_hls_parser.dart';

import 'utils/utils.dart';

void hlsAudio(String url, [HlsMasterPlaylist? master]) async {
  final http = createHttp(userAgent: defaultUserAgent, proxy: '127.0.0.1:7890');

  final uri = Uri.parse(url);
  final res = await http.get(url);
  debugPrint('内容 ${res.data}');

  late HlsPlaylist playlist;
  try {
    playlist = await HlsPlaylistParser.create(masterPlaylist: master)
        .parseString(uri, res.data);
  } catch (e) {
    debugPrint(e.toString());
  }

  if (playlist is HlsMasterPlaylist) {
    // master m3u8 file
    debugPrint('视频流 ${playlist.variants.length}');
    debugPrint('音频流 ${playlist.audios.length}');
    debugPrint('字幕 ${playlist.subtitles.length}');
    playlist.variants.forEach((variant) {
      debugPrint('variants ${[
        variant.format.id,
        variant.videoGroupId,
        variant.audioGroupId,
        variant.subtitleGroupId,
        variant.url,
      ].join('|')}');
    });
  } else if (playlist is HlsMediaPlaylist) {
    // media m3u8 file
  }
}
