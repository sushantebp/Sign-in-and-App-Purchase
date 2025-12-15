import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationService {
  Future<AuthorizationCredentialAppleID> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: _scopes,
    );
    return credential;
  }

  static const List<AppleIDAuthorizationScopes> _scopes = [
    AppleIDAuthorizationScopes.email,
    AppleIDAuthorizationScopes.fullName,
  ];
}
