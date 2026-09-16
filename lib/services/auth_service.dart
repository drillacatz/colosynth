import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:colosynth/services/fcm_service.dart';
import 'package:colosynth/services/iap_service.dart';
import 'package:colosynth/services/save_manager.dart';
import 'package:colosynth/services/user_data_service.dart';
import 'package:colosynth/services/achievement_service.dart';
import 'package:colosynth/utils/app_logger.dart';
import 'package:colosynth/utils/app_config.dart';

enum AuthFailureReason { cancelled, credentialAlreadyUsed, unknown }

class AuthResult {
  const AuthResult.success(this.user) : failure = null;
  const AuthResult.failure(this.failure) : user = null;

  final User? user;
  final AuthFailureReason? failure;
  bool get isSuccess => user != null;
}

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn.instance;
  final _userDataService = UserDataService();
  bool _googleInitialized = false;

  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isGuest => currentUser?.isAnonymous ?? true;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final clientId = AppConfig.firebaseWebOAuthClientId;

    if (Platform.isAndroid && clientId.isEmpty) {
      throw StateError(
        'FIREBASE_WEB_OAUTH_CLIENT_ID is required on Android.\n'
        'Add --dart-define=FIREBASE_WEB_OAUTH_CLIENT_ID=<web_client_id> '
        'to your flutter run / build command.\n'
        'Get it from Firebase Console → Project Settings → '
        'Web apps → OAuth 2.0 Client IDs → '
        '"Web client (auto created by Google Service)".',
      );
    }

    if (clientId.isNotEmpty) {
      await _googleSignIn.initialize(serverClientId: clientId);
    } else {
      await _googleSignIn.initialize();
    }
    _googleInitialized = true;
  }

  Future<User?> signInAnonymously() async {
    try {
      final result =
          await _auth.signInAnonymously().timeout(const Duration(seconds: 8));
      final user = result.user;
      if (user != null) {
        await _userDataService.initUser(user.uid, isGuest: true);
        await _postSignInSetup(user.uid);
      }
      return user;
    } catch (e) {
      AppLogger.e('AuthService',
          'signInAnonymously failed ($e). Falling back to offline local guest account.');
      await _postSignInSetup('local_guest_offline');
      return null;
    }
  }

  Future<AuthResult> signInWithGoogleDetailed() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.authenticate();
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' ||
          e.code == 'sign_in_failed' ||
          e.message?.contains('12501') == true) {
        return const AuthResult.failure(AuthFailureReason.cancelled);
      }
      rethrow;
    }

    final authentication = account.authentication;
    final idToken = authentication.idToken;

    final scopes = ['email', 'profile'];
    GoogleSignInClientAuthorization? auth =
        await account.authorizationClient.authorizationForScopes(scopes);
    auth ??= await account.authorizationClient.authorizeScopes(scopes);
    final accessToken = auth.accessToken;

    if (idToken == null) {
      return const AuthResult.failure(AuthFailureReason.unknown);
    }

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    if (isGuest && currentUser != null) {
      try {
        await SaveManager.instance.forcePushToCloud();
        final linked = await currentUser!.linkWithCredential(credential);
        final user = linked.user!;
        await _userDataService.initUser(user.uid, isGuest: false);
        await _postSignInSetup(user.uid);
        return AuthResult.success(user);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          await SaveManager.instance.forcePushToCloud();
          final user = await _mergeAndSignIn(credential);
          if (user == null) {
            return const AuthResult.failure(AuthFailureReason.unknown);
          }
          await _postSignInSetup(user.uid);
          return AuthResult.success(user);
        }
        rethrow;
      }
    }

    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;
    await _userDataService.initUser(user.uid, isGuest: false);
    await _postSignInSetup(user.uid);
    return AuthResult.success(user);
  }

  Future<void> _postSignInSetup(String uid) async {
    await SaveManager.instance.bindUser(uid);
    await IapService.instance.logIn(uid);
    await FcmService.instance.bindUser(uid);


    unawaited(AchievementService.instance.signIn(manual: false));
  }

  Future<User?> _mergeAndSignIn(AuthCredential credential) async {
    final guestUid = currentUser?.uid;
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null) return null;
    if (guestUid != null) {
      await _userDataService.migrateGuestData(guestUid, user.uid);
    }
    return user;
  }

  Future<void> signOut() async {
    if (isGuest) return;
    final uid = currentUser?.uid;
    if (uid != null) {
      await FcmService.instance.unbindUser(uid);
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await AchievementService.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
    await IapService.instance.logOut();
    await SaveManager.instance.unbindUser();
    await signInAnonymously();
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;
    final uid = user.uid;
    await FcmService.instance.unbindUser(uid);
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await AchievementService.instance.signOut();
    } catch (_) {}
    await _userDataService.deleteUser(uid);
    await IapService.instance.logOut();
    await SaveManager.instance.unbindUser();
    await user.delete();
    await signInAnonymously();
  }

  Future<void> refreshUser() async {
    await _auth.currentUser?.reload();
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService.instance);
