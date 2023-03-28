// import 'dart:convert';

// import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_chat_research/auth/firebase_auth_failure.dart';
// import 'package:flutter_chat_research/auth/models/models.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// /// {@template authentication_repository}
// /// Repository which manages user authentication.
// /// {@endtemplate}
// class FirebaseAuthRepository {
//   FirebaseAuthRepository({
//     FlutterSecureStorage? cache,
//     firebase_auth.FirebaseAuth? firebaseAuth,
//     GoogleSignIn? googleSignIn,
//   })  : _cache = cache ?? const FlutterSecureStorage(),
//         _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
//         _googleSignIn = googleSignIn ?? GoogleSignIn.standard();

//   final FlutterSecureStorage _cache;
//   final firebase_auth.FirebaseAuth _firebaseAuth;
//   final GoogleSignIn _googleSignIn;

//   bool isWeb = kIsWeb;

//   static const userCacheKey = '__user_cache_key__';

//   /// Stream of [User] which will emit the current user when
//   /// the authentication state changes.
//   ///
//   /// Emits [User.empty] if the user is not authenticated.
//   Stream<User> get user {
//     return _firebaseAuth.authStateChanges().map((firebaseUser) {
//       final user = firebaseUser == null ? User.empty : firebaseUser.toUser;
//       _cache.write(key: userCacheKey, value: jsonEncode(user.toJson()));
//       return user;
//     });
//   }

//   /// Returns the current cached user.
//   /// Defaults to [User.empty] if there is no cached user.
//   User get currentUser {
//     try {
//       String? value;
//       _cache.read(key: userCacheKey).then((result) {
//         value = result;
//       });

//       if (value == null) return User.empty;

//       return User.fromJson(jsonDecode(value!));
//     } catch (_) {
//       return User.empty;
//     }
//   }

//   /// Creates a new user with the provided [email] and [password].
//   ///
//   /// Throws a [SignUpWithEmailAndPasswordFailure] if an exception occurs.
//   Future<void> signUp({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       await _firebaseAuth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } on firebase_auth.FirebaseAuthException catch (e) {
//       throw SignUpWithEmailAndPasswordFailure.fromCode(e.code);
//     } catch (e) {
//       throw const SignUpWithEmailAndPasswordFailure();
//     }
//   }

//   /// Starts the Sign In with Google Flow.
//   ///
//   /// Throws a [LogInWithGoogleFailure] if an exception occurs.
//   Future<void> logInWithGoogle() async {
//     try {
//       late final firebase_auth.AuthCredential credential;

//       if (isWeb) {
//         final googleProvider = firebase_auth.GoogleAuthProvider();
//         final userCredential = await _firebaseAuth.signInWithPopup(
//           googleProvider,
//         );
//         credential = userCredential.credential!;
//       } else {
//         final googleUser = await _googleSignIn.signIn();
//         final googleAuth = await googleUser!.authentication;
//         credential = firebase_auth.GoogleAuthProvider.credential(
//           accessToken: googleAuth.accessToken,
//           idToken: googleAuth.idToken,
//         );
//       }

//       await _firebaseAuth.signInWithCredential(credential);
//     } on firebase_auth.FirebaseAuthException catch (e) {
//       throw LogInWithGoogleFailure.fromCode(e.code);
//     } catch (_) {
//       throw const LogInWithGoogleFailure();
//     }
//   }

//   /// Signs in with the provided [email] and [password].
//   ///
//   /// Throws a [LogInWithEmailAndPasswordFailure] if an exception occurs.
//   Future<void> logInWithEmailAndPassword({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       await _firebaseAuth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//     } on firebase_auth.FirebaseAuthException catch (e) {
//       throw LogInWithEmailAndPasswordFailure.fromCode(e.code);
//     } catch (_) {
//       throw const LogInWithEmailAndPasswordFailure();
//     }
//   }

//   Future<void> logOut() async {
//     try {
//       await Future.wait([
//         _firebaseAuth.signOut(),
//         _googleSignIn.signOut(),
//       ]);
//     } catch (_) {
//       throw LogOutFailure();
//     }
//   }
// }

// extension on firebase_auth.User {
//   User get toUser {
//     return User(id: uid, email: email, name: displayName, photo: photoURL);
//   }
// }
