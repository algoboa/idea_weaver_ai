import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Robot for interacting with authentication screens
class AuthRobot {
  final WidgetTester tester;

  AuthRobot(this.tester);

  /// Enter text in the email field
  Future<void> enterEmail(String email) async {
    final emailField = find.byType(TextFormField).first;
    await tester.enterText(emailField, email);
    await tester.pump();
  }

  /// Enter text in the password field
  Future<void> enterPassword(String password) async {
    final passwordField = find.byType(TextFormField).at(1);
    await tester.enterText(passwordField, password);
    await tester.pump();
  }

  /// Enter text in the name field (register screen)
  Future<void> enterName(String name) async {
    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, name);
    await tester.pump();
  }

  /// Enter text in the confirm password field (register screen)
  Future<void> enterConfirmPassword(String password) async {
    final confirmField = find.byType(TextFormField).at(3);
    await tester.enterText(confirmField, password);
    await tester.pump();
  }

  /// Tap the Sign In button
  Future<void> tapSignIn() async {
    final signInButton = find.text('Sign In');
    if (signInButton.evaluate().isNotEmpty) {
      await tester.tap(signInButton.first);
      await tester.pump();
    }
  }

  /// Tap the Sign Up link
  Future<void> tapSignUp() async {
    final signUpButton = find.text('Sign Up');
    if (signUpButton.evaluate().isNotEmpty) {
      await tester.tap(signUpButton.first);
      await tester.pump();
    }
  }

  /// Tap the Create Account button
  Future<void> tapCreateAccount() async {
    final createButton = find.text('Create Account');
    if (createButton.evaluate().isNotEmpty) {
      await tester.tap(createButton.first);
      await tester.pump();
    }
  }

  /// Tap the Forgot Password link
  Future<void> tapForgotPassword() async {
    final forgotButton = find.text('Forgot Password?');
    if (forgotButton.evaluate().isNotEmpty) {
      await tester.tap(forgotButton.first);
      await tester.pump();
    }
  }

  /// Tap Google sign in button
  Future<void> tapGoogleSignIn() async {
    final googleButton = find.text('Google');
    if (googleButton.evaluate().isNotEmpty) {
      await tester.tap(googleButton.first);
      await tester.pump();
    }
  }

  /// Tap Apple sign in button
  Future<void> tapAppleSignIn() async {
    final appleButton = find.text('Apple');
    if (appleButton.evaluate().isNotEmpty) {
      await tester.tap(appleButton.first);
      await tester.pump();
    }
  }

  /// Verify error message is displayed
  void verifyErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Verify we're on the login screen
  void verifyOnLoginScreen() {
    expect(find.text('Idea Weaver AI'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  }

  /// Verify we're on the register screen
  void verifyOnRegisterScreen() {
    expect(find.text('Create Account'), findsWidgets);
    expect(find.text('Full Name'), findsOneWidget);
  }

  /// Toggle password visibility
  Future<void> togglePasswordVisibility() async {
    final visibilityToggle = find.byIcon(Icons.visibility_outlined);
    if (visibilityToggle.evaluate().isNotEmpty) {
      await tester.tap(visibilityToggle.first);
      await tester.pump();
    }
  }
}
