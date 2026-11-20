import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bonkilingo/core/utils/error_message_helper.dart';

void main() {
  test('confirmation email failure from Supabase reads as a sentence', () {
    final error = AuthException(
      '{"code":"unexpected_failure","message":"Error sending confirmation email"}',
      statusCode: '500',
    );
    final message = ErrorMessageHelper.getUserFriendlyMessage(error);
    expect(message, contains("couldn't send your confirmation email"));
    expect(message, isNot(contains('{')));
  });

  test('other unexpected server failures never show raw JSON', () {
    final error = AuthException(
      '{"code":"unexpected_failure","message":"Database error"}',
      statusCode: '500',
    );
    expect(
        ErrorMessageHelper.getUserFriendlyMessage(error), isNot(contains('{')));
  });

  test('wrong password still reads as before', () {
    final error = AuthException('Invalid login credentials', statusCode: '400');
    expect(ErrorMessageHelper.getUserFriendlyMessage(error),
        contains('Invalid email or password'));
  });
}
