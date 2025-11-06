import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../providers/mood_journal_provider.dart';
import 'user_state_repository.dart';

class FirebaseAuthService extends ChangeNotifier {
  FirebaseAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn;

  MoodJournalProvider? _moodJournalProvider;
  UserStateRepository? _userStateRepository;

  StreamSubscription<User?>? _authSubscription;
  Timer? _debounceTimer;

  User? _user;
  bool _isSigningIn = false;
  bool _isInitialSyncInProgress = false;
  bool _initialAuthEventReceived = false;
  bool _pauseSync = false;
  bool _pendingInitialSync = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isSigningIn => _isSigningIn;
  bool get isInitialSyncInProgress => _isInitialSyncInProgress;
  bool get hasCompletedInitialAuth => _initialAuthEventReceived;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isSigningIn || !_initialAuthEventReceived || _isInitialSyncInProgress;

  void updateDependencies({
    required MoodJournalProvider moodJournalProvider,
    required UserStateRepository userStateRepository,
  }) {
    if (_moodJournalProvider != moodJournalProvider) {
      _moodJournalProvider?.removeListener(_onMoodJournalChanged);
      _moodJournalProvider = moodJournalProvider;
      _moodJournalProvider?.addListener(_onMoodJournalChanged);
    }
    _userStateRepository = userStateRepository;

    _authSubscription ??= _auth.authStateChanges().listen(
      (user) => _handleAuthStateChanged(user),
      onError: (Object error, StackTrace stackTrace) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );

    _maybeStartInitialSync();
  }

  Future<void> signInWithGoogle() async {
    if (_isSigningIn) {
      return;
    }
    _errorMessage = null;
    _isSigningIn = true;
    notifyListeners();
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message ?? error.code;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSigningIn = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _pendingInitialSync = false;
    _pauseSync = false;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    _initialAuthEventReceived = true;
    _user = firebaseUser;

    if (firebaseUser == null) {
      _pendingInitialSync = false;
      _isInitialSyncInProgress = false;
      _pauseSync = false;
      _debounceTimer?.cancel();
      notifyListeners();
      return;
    }

    _pendingInitialSync = true;
    notifyListeners();
    await _maybeStartInitialSync();
  }

  Future<void> _maybeStartInitialSync() async {
    if (!_pendingInitialSync) {
      return;
    }
    final user = _user;
    final provider = _moodJournalProvider;
    final repository = _userStateRepository;
    if (user == null || provider == null || repository == null) {
      return;
    }

    await provider.ready;
    if (!_pendingInitialSync) {
      return;
    }

    _pendingInitialSync = false;
    _isInitialSyncInProgress = true;
    notifyListeners();

    try {
      final snapshot = await repository.fetchMoodJournal(user.uid);
      if (snapshot != null) {
        _pauseSync = true;
        await provider.applySnapshot(snapshot);
        _pauseSync = false;
      } else {
        await repository.saveMoodJournal(user.uid, provider.snapshot);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to sync mood journal: $error\n$stackTrace');
      _errorMessage ??= 'Unable to sync your progress right now. Please try again.';
    } finally {
      _isInitialSyncInProgress = false;
      notifyListeners();
    }
  }

  void _onMoodJournalChanged() {
    if (_pauseSync || !_initialAuthEventReceived) {
      return;
    }
    if (_user == null || _userStateRepository == null) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 750), _uploadSnapshot);
  }

  Future<void> _uploadSnapshot() async {
    final user = _user;
    final repository = _userStateRepository;
    final provider = _moodJournalProvider;
    if (user == null || repository == null || provider == null) {
      return;
    }

    try {
      await repository.saveMoodJournal(user.uid, provider.snapshot);
    } catch (error, stackTrace) {
      debugPrint('Failed to upload mood journal snapshot: $error\n$stackTrace');
      _errorMessage = 'We hit a snag while saving your progress. Changes will retry automatically.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _moodJournalProvider?.removeListener(_onMoodJournalChanged);
    _debounceTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
