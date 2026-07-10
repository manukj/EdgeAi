import 'dart:async';

import 'package:edge_ai/edge_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

/// A single message in the conversation transcript shown in the example UI.
class _ChatMessage {
  _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  String text;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  EdgeAiAvailability? _availability;
  EdgeAiDownloadProgress? _downloadProgress;
  final List<_ChatMessage> _messages = [];
  bool _isGenerating = false;
  final _edgeGenaiPlugin = EdgeAi(useMemory: true);
  final _promptController = TextEditingController(
    text: 'Write a 3 sentence story about a magical dog.',
  );

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    EdgeAiAvailability availability;
    try {
      availability = await _edgeGenaiPlugin.checkAvailability();
    } on PlatformException {
      availability = EdgeAiAvailability.unavailable;
    }

    if (!mounted) return;

    setState(() {
      _availability = availability;
    });
  }

  void _downloadModel() {
    _edgeGenaiPlugin.downloadModel().listen(
      (progress) {
        if (!mounted) return;
        setState(() => _downloadProgress = progress);
      },
      onError: (Object error) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $error')));
      },
    );
  }

  void _generateContent() {
    final prompt = _promptController.text;
    if (prompt.trim().isEmpty) return;

    final modelMessage = _ChatMessage(isUser: false, text: '');
    setState(() {
      _isGenerating = true;
      _messages.add(_ChatMessage(isUser: true, text: prompt));
      _messages.add(modelMessage);
    });
    _promptController.clear();

    _edgeGenaiPlugin.generateContent(prompt).listen(
      (chunk) {
        if (!mounted) return;
        setState(() => modelMessage.text = chunk);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isGenerating = false;
          modelMessage.text = 'Failed to generate content: $error';
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() => _isGenerating = false);
      },
    );
  }

  Future<void> _resetConversation() async {
    await _edgeGenaiPlugin.resetConversation();
    if (!mounted) return;
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    final canDownload = _availability == EdgeAiAvailability.downloadable;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
          actions: [
            IconButton(
              onPressed: _messages.isEmpty ? null : _resetConversation,
              icon: const Icon(Icons.refresh),
              tooltip: 'New conversation',
            ),
          ],
        ),
        body: Column(
          children: [
            Text(
              'On-device model availability: ${_availability?.name ?? 'Checking...'}',
            ),
            if (_downloadProgress != null)
              Text(
                'Download status: ${_downloadProgress!.status.name}'
                '${_downloadProgress!.bytesDownloaded != null ? ' (${_downloadProgress!.bytesDownloaded} bytes)' : ''}',
              ),
            if (canDownload)
              ElevatedButton(
                onPressed: _downloadModel,
                child: const Text('Download model'),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.blue.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(message.text),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: const InputDecoration(labelText: 'Prompt'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isGenerating ? null : _generateContent,
                      child: Text(_isGenerating ? '...' : 'Send'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

