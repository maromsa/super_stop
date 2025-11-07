import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../services/firebase_auth_service.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Consumer<FirebaseAuthService>(
              builder: (context, authService, _) {
                final l10n = AppLocalizations.of(context);
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.self_improvement,
                        size: 72,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n?.authSignInTitle ?? 'Welcome to Super Stop',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n?.authSignInSubtitle ?? 'Connect with your Google account to sync your progress across devices.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (authService.errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            authService.errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          onPressed: authService.isSigningIn
                              ? null
                              : () => authService.signInWithGoogle(),
                          icon: const Icon(Icons.login, size: 24),
                          label: Text(l10n?.authSignInButton ?? 'Continue with Google'),
                        ),
                      ),
                      if (authService.isSigningIn) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
