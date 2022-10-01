import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListTileInt extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  late final RxInt value;
  final int step;
  final void Function(int value) onChange;
  final int Function(int value) verify;
  final Rxn<Timer> timer = Rxn();

  ListTileInt({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.step = 1,
    required int value,
    required this.onChange,
    required this.verify,
  }) : value = RxInt(value)..listen(onChange);

  @override
  Widget build(BuildContext context) {
    Color color = context.theme.primaryColor;
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Text(value.toString())),
          SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                child: Icon(Icons.arrow_drop_up_sharp, color: color),
                onTap: () {
                  timer.value?.cancel();
                  value.value = verify(value.value + step);
                },
                onTapDown: (_) {
                  timer.value?.cancel();
                  timer.value =
                      Timer.periodic(Duration(milliseconds: 400), (timer) {
                    value.value = verify(value.value + step);
                  });
                },
                onTapUp: (_) => timer.value?.cancel(),
              ),
              InkWell(
                child: Icon(Icons.arrow_drop_down_sharp, color: color),
                onTap: () {
                  timer.value?.cancel();
                  value.value = verify(value.value - step);
                },
                onTapDown: (_) {
                  timer.value?.cancel();
                  timer.value =
                      Timer.periodic(Duration(milliseconds: 400), (timer) {
                    value.value = verify(value.value - step);
                  });
                },
                onTapUp: (_) => timer.value?.cancel(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
