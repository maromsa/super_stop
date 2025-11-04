import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:super_stop/l10n/app_localizations.dart';

import '../../models/mood_entry.dart';
import '../../providers/mood_journal_provider.dart';
import '../../router/app_routes.dart';
import '../../widgets/mood_selector.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _skipOnboarding() async {
    if (_isCompleting) return;
    final journal = context.read<MoodJournalProvider>();
    await journal.markOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _goTo(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finishOnboarding(Mood mood) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    final moodJournal = context.read<MoodJournalProvider>();
    await moodJournal.recordMood(mood);
    await moodJournal.markOnboardingComplete();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_currentPage < 2)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(l10n.onboardingSkip),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _currentPage = value),
                children: [
                  _OnboardingIntroPage(l10n: l10n),
                  _OnboardingFeaturesPage(l10n: l10n),
                  _OnboardingMoodPage(
                    l10n: l10n,
                    onMoodSelected: _finishOnboarding,
                    isBusy: _isCompleting,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _OnboardingControls(
              currentPage: _currentPage,
              onNext: () => _goTo((_currentPage + 1).clamp(0, 2)),
              onBack: () => _goTo((_currentPage - 1).clamp(0, 2)),
              l10n: l10n,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingIntroPage extends StatelessWidget {
  const _OnboardingIntroPage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingWelcomeTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingWelcomeBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          Image.asset(
            'assets/images/magic_hat.jpg',
            fit: BoxFit.cover,
            height: 220,
          ),
        ],
      ),
    );
  }
}

class _OnboardingFeaturesPage extends StatelessWidget {
  const _OnboardingFeaturesPage({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final features = <String>[
      l10n.onboardingFeatureGames,
      l10n.onboardingFeatureFocus,
      l10n.onboardingFeatureRewards,
      l10n.onboardingFeatureProgress,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingFeatureTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingMoodPage extends StatelessWidget {
  const _OnboardingMoodPage({required this.l10n, required this.onMoodSelected, required this.isBusy});

  final AppLocalizations l10n;
  final ValueChanged<Mood> onMoodSelected;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.onboardingMoodTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingMoodSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          if (isBusy)
            const CircularProgressIndicator()
          else
            MoodSelector(
              onMoodSelected: onMoodSelected,
              isCompact: true,
            ),
        ],
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.currentPage,
    required this.onNext,
    required this.onBack,
    required this.l10n,
  });

  final int currentPage;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (currentPage > 0)
          OutlinedButton(
            onPressed: onBack,
            child: Text(l10n.onboardingBack),
          ),
        const SizedBox(width: 12),
        if (currentPage < 2)
          FilledButton(
            onPressed: onNext,
            child: Text(l10n.onboardingNext),
          )
        else
          Text(l10n.onboardingMoodPrompt),
      ],
    );
  }
}
