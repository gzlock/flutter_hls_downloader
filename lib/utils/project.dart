import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dynamic_parallel_queue/dynamic_parallel_queue.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'utils.dart';

class SettingKeyValueController<T> {
  final SettingKeyValue<T> value;
  late final StreamSubscription<T> _listener;
  late final controller = TextEditingController(text: value.value.toString());
  late final focusNode = FocusNode();
  final T Function(T)? beforeSave;

  SettingKeyValueController(this.value, [this.beforeSave]) {
    _listener = value._value.listen((val) {
      if (value.value != controller.text) controller.text = val.toString();
    });
    controller.addListener(() {
      T _value = _toValue(controller.text) as T;
      if (beforeSave != null) _value = beforeSave!(_value);
      debugPrint('controller listener $_value');
      value.set(_value);
    });
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        controller.selection =
            TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      }
    });
  }

  Future<void> cancel() => _listener.cancel();

  Object _toValue(String value) {
    switch (T) {
      case String:
        return value.trim();
      case int:
        try {
          return int.parse(value);
        } catch (e) {
          return 0;
        }
      case double:
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      default:
        throw Exception('只允许使用String、int、double三种类型');
    }
  }
}

class SettingKeyValue<T> {
  final Project project;
  final String key;
  final T defaultValue;
  late final Rx<T> _value = Rx<T>(_getValue());
  bool _autoSave = true;

  T get value => _value.value;

  listen(
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _value.listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  set(T value) => _value.value = value;

  SettingKeyValue({
    required this.project,
    required this.key,
    required this.defaultValue,
  }) {
    _checkType();
    _value.listen((val) {
      if (!_autoSave) return;
      if (val is String) {
        val = val.trim() as T;
      }
      debugPrint('save $key $val');
      _project?._data[key] = val;
      Projects.save();
    });
  }

  void _checkType() {
    switch (T) {
      case String:
        break;
      case int:
        break;
      case double:
        break;
      case List<String>:
        break;
      case bool:
        break;
      default:
        throw ArgumentError('类型不正确');
    }
  }

  void reset() {
    _autoSave = false;
    _value.value = _getValue();
    _autoSave = true;
  }

  Project? get _project => Projects.projects[project.id];

  T _getValue() {
    switch (T) {
      case String:
      case int:
      case double:
      case List<String>:
      case bool:
        return (project._data[key] as T?) ?? defaultValue;
      default:
        throw ArgumentError('类型不正确');
    }
  }

  SettingKeyValueController<T> controller({T Function(T)? beforeSave}) =>
      SettingKeyValueController<T>(this, beforeSave);
}

class Project {
  final String id;
  final Map<String, dynamic> _data;

  late final RxString name;
  late final SettingKeyValue<String> hls;
  late final SettingKeyValue<String> proxy;
  late final SettingKeyValue<String> savePath;
  late final SettingKeyValue<String> userAgent;
  late final SettingKeyValue<int> downloadParallel;
  late final SettingKeyValue<int> downloadTimeout;
  late final SettingKeyValue<int> errorRetry;
  late final SettingKeyValue<bool> waterMark;
  late final SettingKeyValue<String> waterMarkText;
  late final SettingKeyValue<int> waterMarkCount;
  late final List<SettingKeyValue> _list;
  late final Queue queue = Queue();
  late final Dio http;

  Project({
    required this.id,
    required String name,
    required Map<String, dynamic> data,
  }) : _data = data {
    this.name = name.obs;
    hls = SettingKeyValue(
      project: this,
      key: 'hls',
      defaultValue: '',
    );
    proxy = SettingKeyValue(
      project: this,
      key: 'proxy',
      defaultValue: '',
    );
    savePath = SettingKeyValue(
      project: this,
      key: 'savePath',
      defaultValue: '',
    );
    userAgent = SettingKeyValue(
      project: this,
      key: 'userAgent',
      defaultValue: defaultUserAgent,
    );
    downloadParallel = SettingKeyValue(
      project: this,
      key: 'downloadParallel',
      defaultValue: 5,
    )..listen((val) => queue.parallel = val);

    downloadTimeout = SettingKeyValue(
      project: this,
      key: 'downloadTimeout',
      defaultValue: 5,
    );
    errorRetry = SettingKeyValue(
      project: this,
      key: 'errorRetry',
      defaultValue: 5,
    );

    waterMark = SettingKeyValue(
      project: this,
      key: 'waterMark',
      defaultValue: false,
    );
    waterMarkText = SettingKeyValue(
      project: this,
      key: 'waterMarkText',
      defaultValue: '',
    );
    waterMarkCount = SettingKeyValue(
      project: this,
      key: 'waterMarkCount',
      defaultValue: 0,
    );

    _list = [
      hls,
      proxy,
      savePath,
      userAgent,
      downloadParallel,
      errorRetry,
      downloadTimeout,
      waterMark,
      waterMarkText,
      waterMarkCount,
    ];
  }

  void save() => Projects.save();

  toJson() => {
        'id': id,
        'name': name.value,
        'data': _data,
      };

  @override
  String toString() => jsonEncode(toJson());

  void reset() async {
    _data.clear();
    for (var kv in _list) {
      kv.reset();
    }
    save();
  }

  factory Project.fromJson(Map map) {
    return Project(id: map['id'], name: map['name'], data: map['data']);
  }
}

class Projects {
  static final RxMap<String, Project> projects = RxMap();

  static load() {
    projects.clear();
    (prefs.getStringList('projects') ?? []).forEach((element) {
      final map = jsonDecode(element);
      final project = Project.fromJson(map);
      projects[project.id] = project;
    });
  }

  static void save() {
    final values = projects.values.map((e) => e.toString()).toList();
    debugPrint('保存 $values');
    prefs.setStringList(
      'projects',
      values,
    );
  }
}
