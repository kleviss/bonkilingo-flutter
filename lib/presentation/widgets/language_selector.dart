import 'package:flutter/material.dart';
import '../../core/constants/language_constants.dart';
import '../../core/theme/app_colors.dart';

class LanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;
  final bool enabled;

  const LanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedLanguage,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: LanguageConstants.supportedLanguages.map((language) {
        return DropdownMenuItem(
          value: language.code,
          child: Text(language.name),
        );
      }).toList(),
      onChanged: enabled
          ? (value) {
              if (value != null) {
                onLanguageChanged(value);
              }
            }
          : null,
      icon: const Icon(Icons.arrow_drop_down),
      dropdownColor: AppColors.background,
    );
  }
}

