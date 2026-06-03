import 'package:flutter/material.dart';

class ShellRouteAction {
  const ShellRouteAction({required this.icon, required this.title, this.selectedIcon});

  final Widget icon;
  final Widget? selectedIcon;
  final String title;

  factory ShellRouteAction.material(IconData icon, String title, {IconData? selectedIcon}) {
    return ShellRouteAction(
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon ?? icon),
      title: title,
    );
  }
}
