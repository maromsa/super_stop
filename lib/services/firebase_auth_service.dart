import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../providers/mood_journal_provider.dart';
import 'user_state_repository.dart';

class FirebaseAuthService extends ChangeNotifier {
  FirebaseAuthService({GoogleSignIn? googleSignIn, bool bypassAuth = false})
      : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _bypassAuth = bypassAuth,
        _auth = bypassAuth ? null : FirebaseAuth.instance {
    if (_bypassAuth) {
      _initialAuthEventReceived = true;
    } else {
      _authSubscription = _auth!.authStateChanges().listen(
        _handleAuthStateChanged,
        onError: (Object error, StackTrace stackTrace) {
          _errorMessage = error.toString();
          notifyListeners();
        },
      );
    }
  }

  final FirebaseAuth? _auth;
  final GoogleSignIn _googleSignIn;
  final bool _bypassAuth;

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
  bool get isInitialSyncInProgress => _bypassAuth ? false : _isInitialSyncInProgress;
  bool get hasCompletedInitialAuth => _bypassAuth || _initialAuthEventReceived;
  String? get errorMessage => _errorMessage;
  bool get isAuthBypassed => _bypassAuth;
  bool get isBusy => _isSigningIn || !hasCompletedInitialAuth || isInitialSyncInProgress;

  void updateDependencies({
    required MoodJournalProvider moodJournalProvider,
    required UserStateRepository userStateRepository,
  }) {
    if (_moodJournalProvider != moodJournalProvider) {
      _moodJournalProvider?.removeListener(_onMoodJournalChanged);
      _moodJournalProvider = moodJournalProvider;
      if (!_bypassAuth) {
        _moodJournalProvider?.addListener(_onMoodJournalChanged);
      }
    }

    if (_bypassAuth) {
      return;
    }

    _userStateRepository = userStateRepository;
    _maybeStartInitialSync();
  }

  Future<void> signInWithGoogle() async {
    if (_isSigningIn) {
      return;
    }
    _errorMessage = null;
    _isSigningIn = true;
    notifyListeners();

    if (_auth == null) {
      _isSigningIn = false;
      notifyListeners();
      return;
    }

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

      await _auth!.signInWithCredential(credential);
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
    if (_auth != null) {
      await _auth!.signOut();
      await _googleSignIn.signOut();
    }
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
    if (_bypassAuth) {
      return;
    }

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
    if (_bypassAuth) {
      return;
    }
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
    if (_bypassAuth || _pauseSync || !_initialAuthEventReceived) {
      return;
    }
    if (_user == null || _userStateRepository == null) {
      return;
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 750), _uploadSnapshot);
  }

  Future<void> _uploadSnapshot() async {
    if (_bypassAuth) {
      return;
    }
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
