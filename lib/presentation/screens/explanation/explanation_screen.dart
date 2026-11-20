import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/pill_button.dart';
import '../../screens/main_navigation.dart';
import '../learn/learn_provider.dart';
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

  void _showSuccessDialog(String lessonId) {
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
            child: const Text('Keep talking'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToLesson(lessonId);
            },
            child: const Text('View lesson'),
          ),
        ],
      ),
    );
  }

  void _navigateToLesson(String lessonId) {
    // Set flashcards tool active and expand the lesson first
    ref.read(learnStateProvider.notifier).setActiveTool(
          LearnTool.flashcards,
          lessonToExpand: lessonId,
        );

    // Pop back to root navigation
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Navigate to Learn tab (index 2) after popping
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationIndexProvider.notifier).state = 2;
    });
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    // Scroll to bottom when messages change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Show success dialog when lesson is created
    if (explanationState.lessonCreated &&
        explanationState.createdLessonId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSuccessDialog(explanationState.createdLessonId!);
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

    final canSend = _textController.text.trim().isNotEmpty;

    return BrandPage(
      isDark: isDark,
      title: 'Explanation',
      child: Column(
        children: [
          // Corrected text
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: BrandCard(
              palette: p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: BrandPalette.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Corrected text',
                        style: TextStyle(fontSize: 12, color: p.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.correctedText,
                    style: TextStyle(fontSize: 17, height: 1.45, color: p.text),
                  ),
                ],
              ),
            ),
          ),

          // Messages
          Expanded(
            child: explanationState.isLoading &&
                    explanationState.messages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: BrandCard(
                        palette: p,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          children: [
                            const CupertinoActivityIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              'Explaining your correction…',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: p.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    itemCount: explanationState.messages.length,
                    itemBuilder: (context, index) {
                      final message = explanationState.messages[index];
                      return _MessageBubble(
                        palette: p,
                        text: message.text,
                        isUser: message.sender == 'user',
                      );
                    },
                  ),
          ),

          // Composer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (explanationState.messages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Center(
                      child: SecondaryPillButton(
                        palette: p,
                        height: 40,
                        icon: Icons.lightbulb_outline,
                        label: explanationState.isCreatingLesson
                            ? 'Creating…'
                            : 'Create lesson from chat',
                        onPressed: explanationState.isCreatingLesson
                            ? null
                            : () {
                                ref
                                    .read(explanationStateProvider.notifier)
                                    .createTinyLesson();
                              },
                      ),
                    ),
                  ),
                _ComposerField(
                  palette: p,
                  controller: _textController,
                  placeholder: 'Ask a question…',
                  onChanged: (_) =>
                      setState(() {}), // Rebuild to update button state
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'Send',
                  loading: explanationState.isLoading,
                  onPressed: !canSend || explanationState.isLoading
                      ? null
                      : () {
                          final text = _textController.text.trim();
                          ref
                              .read(explanationStateProvider.notifier)
                              .sendMessage(text);
                          _textController.clear();
                          setState(() {}); // Update button state
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A chat message: the learner's on a sunny tint at the right, the
/// explanation on a card at the left.
class _MessageBubble extends StatelessWidget {
  final BrandPalette palette;
  final String text;
  final bool isUser;

  const _MessageBubble({
    required this.palette,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Color.alphaBlend(
                  BrandColors.sunny.withValues(alpha: p.isDark ? 0.2 : 0.4),
                  p.card,
                )
              : p.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: isUser ? null : p.cardShadow,
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, height: 1.4, color: p.text),
        ),
      ),
    );
  }
}

/// Question field as a soft card with a tangerine ring while focused.
class _ComposerField extends StatefulWidget {
  final BrandPalette palette;
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const _ComposerField({
    required this.palette,
    required this.controller,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  State<_ComposerField> createState() => _ComposerFieldState();
}

class _ComposerFieldState extends State<_ComposerField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _focus.hasFocus ? BrandColors.tangerine : const Color(0x00000000),
          width: 1.5,
        ),
        boxShadow: p.cardShadow,
      ),
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focus,
        placeholder: widget.placeholder,
        maxLines: 3,
        minLines: 1,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: null,
        cursorColor: BrandColors.tangerine,
        style: TextStyle(fontSize: 16, color: p.text),
        placeholderStyle: TextStyle(fontSize: 16, color: p.muted),
        onChanged: widget.onChanged,
      ),
    );
  }
}
