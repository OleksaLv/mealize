import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_strings.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw AuthException(AppStrings.authWeakPassword);
      } else if (e.code == 'email-already-in-use') {
        throw AuthException(AppStrings.authEmailInUse);
      } else if (e.code == 'invalid-email') {
        throw AuthException(AppStrings.authInvalidEmail);
      } else {
        throw AuthException(AppStrings.authErrorOccurred);
      }
    } catch (e) {
      throw AuthException(AppStrings.authUnknownError);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw AuthException(AppStrings.authInvalidCredential);
      } else if (e.code == 'invalid-email') {
        throw AuthException(AppStrings.authInvalidEmail);
      } else if (e.code == 'user-disabled') {
        throw AuthException(AppStrings.authUserDisabled);
      } else {
        throw AuthException(AppStrings.authErrorOccurred);
      }
    } catch (e) {
      throw AuthException(AppStrings.authUnknownError);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, 
        idToken: googleAuth.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      throw AuthException(AppStrings.authGoogleError);
    } on FirebaseAuthException {
      throw AuthException(AppStrings.authGoogleAuthError);
    } catch (e) {
      throw AuthException(AppStrings.authUnknownError);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException(AppStrings.authSignOutError);
    }
  }
}