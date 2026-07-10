import 'dart:async';

import 'package:edge_ai/edge_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EdgeGenAi',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('EdgeGenAi'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
                Tab(icon: Icon(Icons.summarize_outlined), text: 'Summarize'),
                Tab(icon: Icon(Icons.spellcheck), text: 'Proofread'),
                Tab(icon: Icon(Icons.auto_fix_high), text: 'Rewrite'),
                Tab(icon: Icon(Icons.image_outlined), text: 'Describe image'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              ChatPage(),
              SummarizePage(),
              ProofreadPage(),
              RewritePage(),
              ImageDescriptionPage(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card that displays a one-shot tool's result, used by the summarize,
/// proofread, rewrite, and image description tabs.
class _ResultCard extends StatelessWidget {
  const _ResultCard(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text),
      ),
    );
  }
}

/// A single message in the conversation transcript shown in the example UI.
class _ChatMessage {
  _ChatMessage({required this.isUser, required this.text, this.image});

  final bool isUser;
  String text;
  final Uint8List? image;
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
  var _prompt = EdgeGenAIPrompt(useMemory: true);
  final _promptController = TextEditingController(
    text: 'Write a 3 sentence story about a magical dog.',
  );
  Uint8List? _pendingImage;

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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() => _pendingImage = bytes);
  }

  void _generateContent() {
    final prompt = _promptController.text;
    if (prompt.trim().isEmpty) return;
    final image = _pendingImage;

    final modelMessage = _ChatMessage(isUser: false, text: '');
    setState(() {
      _isGenerating = true;
      _messages.add(_ChatMessage(isUser: true, text: prompt, image: image));
      _messages.add(modelMessage);
      _pendingImage = null;
    });
    _promptController.clear();

    _prompt
        .generateContent(prompt, image: image)
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

  void _setUseMemory(bool useMemory) {
    if (useMemory == _prompt.useMemory) return;
    // useMemory is fixed per EdgeGenAIPrompt instance, so switching it means
    // starting a fresh conversation on a new instance.
    setState(() {
      _prompt = EdgeGenAIPrompt(useMemory: useMemory);
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canDownload = _availability == EdgeGenAIAvailability.downloadable;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Icon(
                switch (_availability) {
                  EdgeGenAIAvailability.available => Icons.check_circle,
                  EdgeGenAIAvailability.downloadable => Icons.cloud_download,
                  null => Icons.hourglass_empty,
                  _ => Icons.error_outline,
                },
                size: 18,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Availability: ${_availability?.name ?? 'Checking...'}'
                  '${_downloadProgress != null ? ' — ${_downloadProgress!.status.name}'
                        '${_downloadProgress!.bytesDownloaded != null ? ' (${_downloadProgress!.bytesDownloaded} bytes)' : ''}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (canDownload)
                TextButton(
                  onPressed: _downloadModel,
                  child: const Text('Download'),
                ),
              const Icon(Icons.memory, size: 18),
              Switch(
                value: _prompt.useMemory,
                onChanged: _setUseMemory,
              ),
              IconButton(
                onPressed: _messages.isEmpty ? null : _resetConversation,
                icon: const Icon(Icons.refresh),
                tooltip: 'New conversation',
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text(
                    'Say hello to get started.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
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
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.image != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    message.image!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            Text(message.text),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pendingImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _pendingImage!,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, size: 18),
                            onPressed: () =>
                                setState(() => _pendingImage = null),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _isGenerating ? null : _pickImage,
                      icon: const Icon(Icons.image_outlined),
                      tooltip: 'Attach image',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        decoration: InputDecoration(
                          hintText: 'Message',
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isGenerating ? null : _generateContent,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A one-shot text tool demo page: enter text, run [action], show the
/// result. Shared by the summarize and proofread tabs, which only differ
/// in their initial text, button label, and action.
class _TextToolPage extends StatefulWidget {
  const _TextToolPage({
    required this.initialText,
    required this.buttonLabel,
    required this.icon,
    required this.action,
  });

  final String initialText;
  final String buttonLabel;
  final IconData icon;
  final Future<String> Function(String text) action;

  @override
  State<_TextToolPage> createState() => _TextToolPageState();
}

class _TextToolPageState extends State<_TextToolPage>
    with AutomaticKeepAliveClientMixin {
  late final _controller = TextEditingController(text: widget.initialText);
  String? _result;
  bool _isRunning = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    setState(() {
      _isRunning = true;
      _result = null;
    });
    String result;
    try {
      result = await widget.action(text);
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
            controller: _controller,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Text',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isRunning ? null : _run,
            icon: _isRunning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(widget.icon),
            label: Text(widget.buttonLabel),
          ),
          const SizedBox(height: 16),
          if (_result != null) _ResultCard(_result!),
        ],
      ),
    );
  }
}

/// Demo of [EdgeGenAISummarizer].
class SummarizePage extends StatelessWidget {
  const SummarizePage({super.key});

  @override
  Widget build(BuildContext context) {
    return _TextToolPage(
      // Android's summarizer requires at least 400 characters of input for
      // its default ARTICLE input type, so this needs to be a real
      // paragraph rather than a couple of short sentences.
      initialText:
          'The quick brown fox jumps over the lazy dog. It was a sunny day '
          'and everyone in the neighborhood was outside enjoying the '
          'weather, playing games, and having picnics in the park. Children '
          'rode their bicycles up and down the street while their parents '
          'set up folding chairs and coolers on the front lawns. Someone '
          'brought a portable speaker and played music that could be heard '
          'from several houses away. By the time the sun began to set, '
          'everyone agreed it had been one of the best days of the summer '
          'so far, and several neighbors started planning another '
          'get-together for the following weekend.',
      buttonLabel: 'Summarize',
      icon: Icons.summarize_outlined,
      action: EdgeGenAISummarizer().summarize,
    );
  }
}

/// Demo of [EdgeGenAIProofreader].
class ProofreadPage extends StatelessWidget {
  const ProofreadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _TextToolPage(
      initialText:
          'the quick brown fox jumsp over the lazy dog it was a sunny day '
          'and everyone was outside enjoying the wether',
      buttonLabel: 'Proofread',
      icon: Icons.spellcheck,
      action: EdgeGenAIProofreader().proofread,
    );
  }
}

/// Demo of [EdgeGenAIRewriter], which additionally needs a style picker.
class RewritePage extends StatefulWidget {
  const RewritePage({super.key});

  @override
  State<RewritePage> createState() => _RewritePageState();
}

class _RewritePageState extends State<RewritePage>
    with AutomaticKeepAliveClientMixin {
  final _rewriter = EdgeGenAIRewriter();
  final _controller = TextEditingController(
    text:
        'Hey, can you send me the report when you get a chance? Thanks a '
        'lot!',
  );
  EdgeGenAIRewriteStyle _style = EdgeGenAIRewriteStyle.professional;
  String? _result;
  bool _isRunning = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    setState(() {
      _isRunning = true;
      _result = null;
    });
    String result;
    try {
      result = await _rewriter.rewrite(text, style: _style);
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
            controller: _controller,
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
              FilledButton.icon(
                onPressed: _isRunning ? null : _run,
                icon: _isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: const Text('Rewrite'),
              ),
              DropdownButton<EdgeGenAIRewriteStyle>(
                value: _style,
                items: [
                  for (final style in EdgeGenAIRewriteStyle.values)
                    DropdownMenuItem(value: style, child: Text(style.name)),
                ],
                onChanged: (style) {
                  if (style != null) setState(() => _style = style);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_result != null) _ResultCard(_result!),
        ],
      ),
    );
  }
}

/// Demo of [EdgeGenAIImageDescriber]: pick a photo, then describe it.
class ImageDescriptionPage extends StatefulWidget {
  const ImageDescriptionPage({super.key});

  @override
  State<ImageDescriptionPage> createState() => _ImageDescriptionPageState();
}

class _ImageDescriptionPageState extends State<ImageDescriptionPage>
    with AutomaticKeepAliveClientMixin {
  final _describer = EdgeGenAIImageDescriber();
  Uint8List? _imageBytes;
  String? _result;
  bool _isRunning = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _result = null;
    });
  }

  Future<void> _describe() async {
    final bytes = _imageBytes;
    if (bytes == null) return;
    setState(() {
      _isRunning = true;
      _result = null;
    });
    String result;
    try {
      result = await _describer.describeImage(bytes);
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
    final imageBytes = _imageBytes;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(imageBytes, height: 200, fit: BoxFit.cover),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick image'),
              ),
              FilledButton.icon(
                onPressed: (imageBytes == null || _isRunning)
                    ? null
                    : _describe,
                icon: _isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image_search),
                label: const Text('Describe'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_result != null) _ResultCard(_result!),
        ],
      ),
    );
  }
}

