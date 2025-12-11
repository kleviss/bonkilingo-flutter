import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

final chatHistoryProvider = FutureProvider((ref) async {
  final correctionRepository = ref.watch(correctionRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  
  return await correctionRepository.getChatHistory(currentUser?.id);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: const Text('Correction History'),
      ),
      child: SafeArea(
        child: chatHistory.when(
          data: (sessions) {
            if (sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: theme.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No corrections yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start correcting text to see your history here',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.inputText.truncate(60),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Language: ${session.language.capitalize()}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textSecondary,
                              ),
                            ),
                            if (session.createdAt != null)
                              Text(
                                session.createdAt!.relativeTime,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Divider
                      Container(
                        height: 0.5,
                        color: theme.border,
                      ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.inputText,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Corrected:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.success,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.successLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                session.correctedText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CupertinoActivityIndicator(),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning,
                  size: 48,
                  color: theme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading history',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

