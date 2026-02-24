import 'package:flutter/material.dart';
import 'package:flutter_face_biometrics/flutter_face_biometrics.dart';

class VerifyHomePage extends StatelessWidget {
  const VerifyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Testing App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BiometricVerificationFlow(
        title: 'Verify your identity',
        useSignature: false,
        onVerified: (result) => Navigator.pop(context, true),
        onError: (result) => debugPrint('Verification: $result'),
      ),
    );
  }
}
