import 'dart:async';

import 'package:edge_ai/edge_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Chat'),
                Tab(text: 'Text tools'),
              ],
            ),
          ),
          body: const TabBarView(children: [ChatPage(), TextToolsPage()]),
        ),
      ),
    );
  }
}

/// A single message in the conversation transcript shown in the example UI.
class _ChatMessage {
  _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  String text;
}

/// Chat demo built on [EdgeGenAIPrompt] with conversation memory.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with AutomaticKeepAliveClientMixin {
  EdgeGenAIAvailability? _availability;
  EdgeGenAIDownloadProgress? _downloadProgress;
  final List<_ChatMessage> _messages = [];
  bool _isGenerating = false;
  final _prompt = EdgeGenAIPrompt(useMemory: true);
  final _promptController = TextEditingController(
    text: 'Write a 3 sentence story about a magical dog.',
  );

  @override
  bool get wantKeepAlive => true;

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
    EdgeGenAIAvailability availability;
    try {
      availability = await _prompt.checkAvailability();
    } on PlatformException {
      availability = EdgeGenAIAvailability.unavailable;
    }

    if (!mounted) return;

    setState(() {
      _availability = availability;
    });
  }

  void _downloadModel() {
    _prompt.downloadModel().listen(
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

    _prompt
        .generateContent(prompt)
        .listen(
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
    await _prompt.resetConversation();
    if (!mounted) return;
    setState(() => _messages.clear());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canDownload = _availability == EdgeGenAIAvailability.downloadable;
    return Column(
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
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _messages.isEmpty ? null : _resetConversation,
            icon: const Icon(Icons.refresh),
            label: const Text('New conversation'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}

/// Demo of the one-shot text features: summarize, proofread, and rewrite.
class TextToolsPage extends StatefulWidget {
  const TextToolsPage({super.key});

  @override
  State<TextToolsPage> createState() => _TextToolsPageState();
}

class _TextToolsPageState extends State<TextToolsPage>
    with AutomaticKeepAliveClientMixin {
  final _summarizer = EdgeGenAISummarizer();
  final _proofreader = EdgeGenAIProofreader();
  final _rewriter = EdgeGenAIRewriter();
  final _textController = TextEditingController(
    text:
        'the quick brown fox jumsp over the lazy dog it was a sunny day and '
        'everyone was outside enjoying the wether',
  );
  EdgeGenAIRewriteStyle _rewriteStyle = EdgeGenAIRewriteStyle.professional;
  String? _result;
  bool _isRunning = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String> Function(String text) feature) async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    setState(() {
      _isRunning = true;
      _result = null;
    });
    String result;
    try {
      result = await feature(text);
    } catch (error) {
      result = 'Failed: $error';
    }
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _textController,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning
                    ? null
                    : () => _run(_summarizer.summarize),
                child: const Text('Summarize'),
              ),
              ElevatedButton(
                onPressed: _isRunning
                    ? null
                    : () => _run(_proofreader.proofread),
                child: const Text('Proofread'),
              ),
              ElevatedButton(
                onPressed: _isRunning
                    ? null
                    : () => _run(
                        (text) => _rewriter.rewrite(text, style: _rewriteStyle),
                      ),
                child: const Text('Rewrite'),
              ),
              DropdownButton<EdgeGenAIRewriteStyle>(
                value: _rewriteStyle,
                items: [
                  for (final style in EdgeGenAIRewriteStyle.values)
                    DropdownMenuItem(value: style, child: Text(style.name)),
                ],
                onChanged: (style) {
                  if (style != null) setState(() => _rewriteStyle = style);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isRunning) const Center(child: CircularProgressIndicator()),
          if (_result != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_result!),
            ),
        ],
      ),
    );
  }
}
