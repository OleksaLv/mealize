import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
        throw AuthException('The password is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw AuthException('This email is already in use.');
      } else if (e.code == 'invalid-email') {
        throw AuthException('Invalid email format.');
      } else {
        throw AuthException('An error occurred. Please try again later.');
      }
    } catch (e) {
      throw AuthException('An unknown error occurred.');
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
        throw AuthException('Invalid email or password.');
      } else if (e.code == 'invalid-email') {
         throw AuthException('Invalid email format.');
      } else if (e.code == 'user-disabled') {
         throw AuthException('This account has been disabled.');
      } else {
        throw AuthException('An error occurred. Please try again later.');
      }
    } catch (e) {
      throw AuthException('An unknown error occurred.');
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
      throw AuthException('Google sign-in error. Please try again later.');
    } on FirebaseAuthException {
       throw AuthException('Google authentication error. Please try again later.');
    } catch (e) {
      throw AuthException('An unknown error occurred.');
    }
  }

  // TODO: Add signOut()
}