import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vitalog/core/backend/backend.dart';

void main() {
  test('auth errors map to messages the user can act on', () {
    AuthProblem of(Object e) => Backend.problemOf(e);
    // Wrong email and wrong password are one answer: no account probing.
    expect(
        of(const AuthApiException('Invalid login credentials',
            statusCode: '400', code: 'invalid_credentials')),
        AuthProblem.wrongDetails);
    expect(of(const AuthApiException('slow down', statusCode: '429')),
        AuthProblem.tooManyTries);
    expect(of(const AuthApiException('x', code: 'over_email_send_rate_limit')),
        AuthProblem.tooManyTries);
    expect(of(AuthRetryableFetchException(message: 'no network')),
        AuthProblem.offline);
    expect(of(const AuthApiException('x', code: 'weak_password')),
        AuthProblem.weakPassword);
    expect(of(const AuthApiException('x', code: 'email_not_confirmed')),
        AuthProblem.confirmEmail);
    // Anything else (Google cancelled, unknown) stays generic.
    expect(of(Exception('google')), AuthProblem.other);
  });
}
