import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';
import 'messaging_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmailPassword({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      // Update last login time in Firestore
      if (credential.user != null) {
        final uid = credential.user!.uid;
        await FirestoreService.updateUserLastLogin(uid);
        await MessagingService.instance.registerUserMessaging(uid: uid);
      }
      
      return credential;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  Future<UserCredential> registerWithEmailPassword({required String email, required String password, String? displayName}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }
      
      // Create user document in Firestore
      if (credential.user != null) {
        final uid = credential.user!.uid;
        final userModel = UserModel.fromFirebaseUser(credential.user!);
        await FirestoreService.createUser(userModel);
        await MessagingService.instance.registerUserMessaging(uid: uid);
      }
      
      return credential;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await MessagingService.instance.unregisterUserMessaging(uid: uid);
    }
    await _auth.signOut();
  }

  // Get current user data from Firestore

  Future<UserCredential> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.setCustomParameters({'prompt': 'select_account'});

      final userCred = await _auth.signInWithProvider(provider);

      // Create user in Firestore if not exists
      if (userCred.user != null) {
        final uid = userCred.user!.uid;
        final exists = await FirestoreService.userExists(uid);
        if (!exists) {
          final userModel = UserModel.fromFirebaseUser(userCred.user!);
          await FirestoreService.createUser(userModel);
        } else {
          await FirestoreService.updateUserLastLogin(uid);
        }
        await MessagingService.instance.registerUserMessaging(uid: uid);
      }

      return userCred;
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await FirestoreService.getUser(user.uid);
    }
    return null;
  }

  // Stream of current user data from Firestore
  Stream<UserModel?> get currentUserDataStream {
    final user = _auth.currentUser;
    if (user != null) {
      return FirestoreService.getUserStream(user.uid);
    }
    return Stream.value(null);
  }

  // Update current user data
  Future<void> updateCurrentUserData(UserModel user) async {
    await FirestoreService.updateUser(user);
  }
}


