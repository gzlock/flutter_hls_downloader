import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:oktoast/oktoast.dart';

import 'utils/utils.dart';

final _KEY = 'ilyB29ZdruuQjC45JhBBR7o2Z8WJ26Vg';
final _IV = 'JUMxvVMmszqUTeKn';

//AES加密
aesEncrypt(String plainText) {
  print('加密字符串 $plainText');
  try {
    final key = Key.fromUtf8(_KEY);
    final iv = IV.fromUtf8(_IV);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    print('加密结果 ${encrypted.base64}');
    return encrypted.base64;
  } catch (err) {
    print("aes encode error:$err");
    return plainText;
  }
}

//AES解密
dynamic aesDecrypt(String encrypted) {
  try {
    final key = Key.fromUtf8(_KEY);
    final iv = IV.fromUtf8(_IV);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(encrypted, iv: iv);
    return decrypted;
  } catch (err) {
    print("aes decode error:$err");
    return encrypted;
  }
}

Future<void> parseHls(int channel) async {
  print(jsonEncode({'value': 'E:\\玩很大'}));
  print('channel $channel');
  final http = createHttp(userAgent: defaultUserAgent, proxy: '127.0.0.1:7890');
  final channelRes =
      await http.get('https://api2.4gtv.tv/Channel/GetChannel/$channel');

  final assetId = channelRes.data['Data']['fs4GTV_ID'];
  // {
  //   "fnCHANNEL_ID": "3",
  //   "fsASSET_ID": "4gtv-4gtv002",
  //   "fsDEVICE_TYPE": "pc",
  //   "clsIDENTITY_VALIDATE_ARUS": {"fsVALUE": ""}
  // };
  final value = {
    'fnCHANNEL_ID': channel.toString(),
    'fsASSET_ID': assetId,
    'fsDEVICE_TYPE': 'pc',
    'clsIDENTITY_VALIDATE_ARUS': {'fsVALUE': ''}
  };
  final aesStr = Uri.encodeComponent(aesEncrypt(jsonEncode(value)));
  print('加密后 $aesStr');
  final formData = FormData.fromMap({'value': aesStr});
  final lastRes = await http.post(
    'https://api2.4gtv.tv/Channel/GetChannelUrl3',
    data: 'value=$aesStr',
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
  print('结果 ${lastRes.data}');

  /// {Success: false, Status: 8002, ErrMessage: 02}
  /// 如果返回的是这个，代表IP不行，需要台湾IP
  if (lastRes.data['Status'] == 200) {
    print('解密 ${aesDecrypt(lastRes.data['Data'])}');
  } else {
    showToast('请使用台湾IP');
  }
}
