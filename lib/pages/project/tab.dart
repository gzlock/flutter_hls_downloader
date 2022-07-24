import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProjectTabController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final RxInt index = RxInt(0);
  final List<Tab> tabs;

  late TabController controller;

  ProjectTabController(this.tabs);

  @override
  void onInit() {
    super.onInit();
    controller = TabController(vsync: this, length: tabs.length);
    controller.addListener(() {
      index.value = controller.index;
    });
  }

  @override
  void onClose() {
    controller.dispose();
    super.onClose();
  }
}
