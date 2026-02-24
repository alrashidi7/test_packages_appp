import 'package:flutter/material.dart';
import 'package:flutter_face_biometrics/flutter_face_biometrics.dart';

class EnrollmentHomePage extends StatelessWidget {
  const EnrollmentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Package Testing App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BiometricEnrollmentFlow(
        title: 'We secure you',
        subtitle: 'Enroll your face to protect your identity',
        useSignature: true,
        onSaved: (BiometricExportData data) {
          // Optionally upload to server
          // await exportService.verifyAndUploadBiometricData(registerUrl, data);
          Navigator.pop(context);
        },
        onError: (e) => debugPrint('Enrollment error: $e'),
      ),
    );
  }
}
