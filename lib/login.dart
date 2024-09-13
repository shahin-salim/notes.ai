import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  LoginPage({Key? key}) : super(key: key);

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    print("--------------------------_handleGoogleSignIn---------------------------------");
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    print("GoogleSignInAccount: $googleUser");

    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print("GoogleSignInAuthentication: $googleAuth");
      
      // Send the ID token to your backend
      final response = await http.post(
        Uri.parse('https://your-django-backend.com/auth/google/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'id_token': googleAuth.idToken!,
        }),
      );

      if (response.statusCode == 200) {
        // Successfully authenticated with backend
        final responseData = jsonDecode(response.body);
        // Store the token or user data as needed
        print('Logged in: ${responseData['email']}');
        // Navigate to home page
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print('Failed to authenticate with backend');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text('Sign in with Google'),
          onPressed: () => _handleGoogleSignIn(context),
        ),
      ),
    );
  }
}
