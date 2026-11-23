// LegalScreen = the Terms of Use and the Privacy Policy, in plain words.
// Opened from Register ("I agree to the Terms and Privacy Policy") and
// readable signed in or not (AppRoutes.terms / AppRoutes.privacy).
//
// The text describes what the app really does (Firebase, the AI gateway,
// delete account). If the app changes what it collects, update it here.
//
// Usage:
//   context.push(AppRoutes.privacy);

import 'package:brainly_life/core/theme/theme.dart';
import 'package:brainly_life/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

enum LegalPage { terms, privacy }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});

  final LegalPage page;

  static const String lastUpdated = 'Last updated: November 2026';

  @override
  Widget build(BuildContext context) {
    final (title, sections) = switch (page) {
      LegalPage.terms => ('Terms of Use', _terms),
      LegalPage.privacy => ('Privacy Policy', _privacy),
    };
    final p = context.palette;

    return Scaffold(
      appBar: BaseetAppBar.inner(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenMargin,
          AppSpacing.s2,
          AppSpacing.screenMargin,
          AppSpacing.s8,
        ),
        children: [
          Text(
            lastUpdated,
            style: context.text.bodySmall?.copyWith(color: p.textSecondary),
          ),
          for (final (heading, body) in sections) ...[
            const SizedBox(height: AppSpacing.s5),
            Text(heading, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.s2),
            Text(
              body,
              style: context.text.bodyMedium?.copyWith(
                color: p.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const List<(String, String)> _terms = [
  (
    'Using Baseet',
    'Baseet helps you plan your studies, tasks, habits and focus time. '
        'You need an account to use it, and you are responsible for keeping '
        'your password safe.',
  ),
  (
    'AI suggestions',
    'Some features use AI to suggest study plans, habits and tips. AI can '
        'make mistakes: check every suggestion before you rely on it. '
        'Nothing is added to your plan or tasks until you confirm it. '
        'Baseet does not give medical, legal or financial advice. You can '
        'turn AI off at any time in Settings.',
  ),
  (
    'Fair use',
    'Do not try to break, overload or misuse the app or its AI features. '
        'AI use has a daily limit per account so the service stays '
        'available for everyone.',
  ),
  (
    'Your account',
    'You can delete your account at any time from Settings. This removes '
        'your data and cannot be undone.',
  ),
  (
    'Changes',
    'We may update these terms when the app changes. The date at the top '
        'shows the latest version.',
  ),
];

const List<(String, String)> _privacy = [
  (
    'What we store',
    'Your name, email and settings, and the data you create in the app: '
        'tasks, categories, subjects, study plans, habits and focus '
        'sessions. Your password is never stored by us: Firebase '
        'Authentication keeps only a secure hash of it.',
  ),
  (
    'Where it is stored',
    'Your data is stored in Google Firebase (Authentication, Cloud '
        'Firestore and Cloud Storage). Only you can read and change your '
        'data; security rules block every other user.',
  ),
  (
    'AI features',
    'When you use an AI feature, only the data needed for that request '
        '(for example subject titles, hours and dates) is sent to our AI '
        'provider, Google Gemini, through our own server. Your name, email '
        'and account id are never sent. AI is used only when you ask for it '
        '(except one daily tip), and you can turn it off in Settings.',
  ),
  (
    'What we do not do',
    'We do not sell your data and we do not use it for advertising.',
  ),
  (
    'Deleting your data',
    'Settings > Delete account removes your account and all your data, '
        'including your profile picture. This cannot be undone.',
  ),
];
