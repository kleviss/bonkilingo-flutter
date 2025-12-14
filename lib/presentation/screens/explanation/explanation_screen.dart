import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/theme_provider.dart';
import 'explanation_provider.dart';

class ExplanationScreen extends ConsumerStatefulWidget {
  final String correctedText;
  final String inputText;

  const ExplanationScreen({
    super.key,
    required this.correctedText,
    required this.inputText,
  });

  @override
  ConsumerState<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends ConsumerState<ExplanationScreen> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with the corrected text
    Future.microtask(() {
      ref
          .read(explanationStateProvider.notifier)
          .initialize(widget.correctedText, widget.inputText);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Success!'),
        content: const Text(
          'Lesson created and saved to your cheatsheet! +15 BONK points awarded.',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final explanationState = ref.watch(explanationStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Show success dialog when lesson is created
    if (explanationState.lessonCreated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog();
        // Reset the flag
        ref.read(explanationStateProvider.notifier).resetLessonCreated();
      });
    }

    // Show error dialog if there's an error
    if (explanationState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorDialog(explanationState.error!);
        // Clear error after showing
        ref.read(explanationStateProvider.notifier).clearError();
      });
    }

    return CupertinoPageScaffold(
      backgroundColor: theme.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.background,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(Icons.arrow_back_ios, color: theme.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: Text(
          'Explanation',
          style: TextStyle(color: theme.textPrimary),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Corrected Text Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.infoLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Corrected Text',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.correctedText,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: explanationState.isLoading &&
                      explanationState.messages.isEmpty
                  ? const Center(
                      child: CupertinoActivityIndicator(),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: explanationState.messages.length,
                      itemBuilder: (context, index) {
                        final message = explanationState.messages[index];
                        final isUser = message.sender == 'user';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? theme.primaryLight
                                  : theme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Input Area - Always light background for contrast
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Create Lesson Button
                  if (explanationState.messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: theme.primary,
                        borderRadius: BorderRadius.circular(20),
                        onPressed: explanationState.isCreatingLesson
                            ? null
                            : () {
                                ref
                                    .read(explanationStateProvider.notifier)
                                    .createTinyLesson();
                              },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: CupertinoColors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              explanationState.isCreatingLesson
                                  ? 'Creating...'
                                  : 'Create Lesson from Chat',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Text Input - light gray background
                  CupertinoTextField(
                    controller: _textController,
                    placeholder: 'Ask a question...',
                    maxLines: 3,
                    minLines: 1,
                    padding: const EdgeInsets.all(12),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 16,
                    ),
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5), // Light gray
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E5E5),
                        width: 1,
                      ),
                    ),
                    onChanged: (_) =>
                        setState(() {}), // Rebuild to update button state
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: _textController.text.trim().isEmpty
                          ? CupertinoColors.systemGrey4
                          : CupertinoColors.black,
                      disabledColor: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _textController.text.trim().isEmpty ||
                              explanationState.isLoading
                          ? null
                          : () {
                              final text = _textController.text.trim();
                              ref
                                  .read(explanationStateProvider.notifier)
                                  .sendMessage(text);
                              _textController.clear();
                              setState(() {}); // Update button state
                            },
                      child: explanationState.isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Text(
                              'Send',
                              style: TextStyle(
                                color: _textController.text.trim().isEmpty
                                    ? CupertinoColors.systemGrey
                                    : CupertinoColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
