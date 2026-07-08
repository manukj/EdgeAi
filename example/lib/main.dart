import 'dart:async';

import 'package:edge_genai/edge_genai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  EdgeGenaiAvailability? _availability;
  final _edgeGenaiPlugin = EdgeGenai();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    EdgeGenaiAvailability availability;
    try {
      availability = await _edgeGenaiPlugin.checkAvailability();
    } on PlatformException {
      availability = EdgeGenaiAvailability.unavailable;
    }

    if (!mounted) return;

    setState(() {
      _availability = availability;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Text(
            'On-device model availability: ${_availability?.name ?? 'Checking...'}',
          ),
        ),
      ),
    );
  }
}
