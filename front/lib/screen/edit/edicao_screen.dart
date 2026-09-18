import 'dart:io';

import 'package:flutter/material.dart';

import 'edit_flows_screen.dart';

class EdicaoScreen extends StatelessWidget {
  final File? initialFile;

  const EdicaoScreen({super.key, this.initialFile});

  @override
  Widget build(BuildContext context) {
    return EdicaoImagemScreen(showBack: false, initialFile: initialFile);
  }
}
